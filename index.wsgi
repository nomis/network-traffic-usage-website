# coding: utf8
from xml.sax.saxutils import XMLGenerator
from datetime import datetime, timedelta
import collections
import psycopg2.extras
import psycopg2.pool
import pytz
import time
import tzlocal
import webob
import yaml

with open("config", "r") as f:
	config = yaml.safe_load(f)

tz = tzlocal.get_localzone()

max_pool = 20

pool = psycopg2.pool.ThreadedConnectionPool(5, max_pool, config["dsn"], connection_factory=psycopg2.extras.RealDictConnection)

def getconn(pool, max_conns):
        attempts = max_conns + 1
        conn = None
        while attempts > 0:
                conn = pool.getconn()
                try:
                        conn.isolation_level
                        return conn
                except psycopg2.OperationalError:
                        pool.putconn(conn, close=True)
                        attempts -= 1
        return conn

Period = collections.namedtuple("Period", ["start_name", "end_name", "start_ts", "end_ts"])

class View:
	def __init__(self, uri):
		self.device = config["device"]

		uri = uri[1:].split("/")
		if len(uri) == 1:
			self.date = uri[0]
		elif len(uri) == 2 and uri[0]:
			self.device = uri[0]
			self.date = uri[1]
		else:
			raise RuntimeError

		if len(self.date) not in [0, 4, 6, 8]:
			raise RuntimeError

		if not self.date:
			self.date = "{0:04d}".format(datetime.now().year)

		self.periods = []
		self.parent = {}

		if len(self.date) == 4:
			self.period_type = "Month"
			year = int(self.date)
			self.name = "{0:04d}".format(year)
			for month in range(1, 13):
				local_start = tz.localize(datetime(year, month, 1))
				local_end = tz.localize(datetime(year if month < 12 else year + 1, month + 1 if month < 12 else 1, 1))
				self.periods.append(Period(local_start.strftime("%B"), None, local_start, local_end))
		elif len(self.date) == 6:
			self.period_type = "Day"
			year = int(self.date[0:4])
			month = int(self.date[4:6])
			self.name = "{0:04d}-{1:02d}".format(year, month)
			self.parent = { "name": "{0:04d}".format(year), "uri": "{0:04d}".format(year) }
			start = datetime(year, month, 1)
			end = datetime(year if month < 12 else year + 1, month + 1 if month < 12 else 1, 1)
			while start < end:
				local_start = tz.localize(start)
				local_end = tz.localize(start + timedelta(days=1))
				self.periods.append(Period(local_start.strftime("%d"), None, local_start, local_end))
				start += timedelta(days=1)
		elif len(self.date) == 8:
			self.period_type = "Hour"
			year = int(self.date[0:4])
			month = int(self.date[4:6])
			day = int(self.date[6:8])
			self.name = "{0:04d}-{1:02d}-{2:02d}".format(year, month, day)
			self.parent = { "name": "{0:04d}-{1:02d}".format(year, month), "uri": "{0:04d}{1:02d}".format(year, month) }
			start = tz.localize(datetime(year, month, day)).astimezone(pytz.utc)
			end = datetime(year, month, day) + timedelta(days=1)
			while start.astimezone(tz).replace(tzinfo=None) < end:
				local_start = start.astimezone(tz)
				local_end = (start + timedelta(hours=1)).astimezone(tz)
				self.periods.append(Period(local_start.strftime("%H:%M"), (local_end - timedelta(milliseconds=1)).strftime("%H:%M"), local_start, local_end))
				start += timedelta(hours=1)

def output_usage(doc, view):
	doc.startElement("usage", { "name": view.name })
	if view.parent:
		doc.startElement("parent", { "name": view.parent["name"], "uri": view.parent["uri"] })
		doc.endElement("parent")
	db = getconn(pool, max_pool)
	try:
		c = db.cursor()

		start_periods = [period.start_ts for period in view.periods]
		end_periods = [period.end_ts for period in view.periods]
		now = time.time()
		c.execute("SELECT"
			+ " period.start"
			+ ", floor(sum(bp.rx_bytes"
					+ "+ (CASE WHEN bp.start < period.start THEN extract(epoch from (bp.stop - period.start))/extract(epoch from (bp.stop - bp.start)) * rx_bytes ELSE 0 END)"
					+ "+ (CASE WHEN bp.stop > period.stop THEN extract(epoch from (bp.stop - period.stop))/extract(epoch from (bp.stop - bp.start)) * rx_bytes ELSE 0 END)"
					+ "))::bigint AS rx_bytes"
				+ ", floor(sum(bp.tx_bytes"
					+ "+ (CASE WHEN bp.start < period.start THEN extract(epoch from (bp.stop - period.start))/extract(epoch from (bp.stop - bp.start)) * tx_bytes ELSE 0 END)"
					+ "+ (CASE WHEN bp.stop > period.stop THEN extract(epoch from (bp.stop - period.stop))/extract(epoch from (bp.stop - bp.start)) * tx_bytes ELSE 0 END)"
					+ "))::bigint AS tx_bytes"
				+ ", floor(sum(bp.rx_packets"
					+ "+ (CASE WHEN bp.start < period.start THEN extract(epoch from (bp.stop - period.start))/extract(epoch from (bp.stop - bp.start)) * rx_packets ELSE 0 END)"
					+ "+ (CASE WHEN bp.stop > period.stop THEN extract(epoch from (bp.stop - period.stop))/extract(epoch from (bp.stop - bp.start)) * rx_packets ELSE 0 END)"
					+ "))::bigint AS rx_packets"
				+ ", floor(sum(bp.tx_packets"
					+ "+ (CASE WHEN bp.start < period.start THEN extract(epoch from (bp.stop - period.start))/extract(epoch from (bp.stop - bp.start)) * tx_packets ELSE 0 END)"
					+ "+ (CASE WHEN bp.stop > period.stop THEN extract(epoch from (bp.stop - period.stop))/extract(epoch from (bp.stop - bp.start)) * tx_packets ELSE 0 END)"
					+ "))::bigint AS tx_packets"
				+ " FROM bp_stats bp, unnest(%(start)s, %(stop)s) AS period(start, stop)"
				+ " WHERE intf = (SELECT id FROM intf_name WHERE name=%(device)s) "
				+ " AND ((bp.start >= period.start and bp.start < period.start) or (bp.stop >= period.start and bp.stop < period.stop))"
				+ " GROUP BY period.start"
				+ " ORDER BY period.start",
				{ "device": view.device, "start": start_periods, "stop": end_periods })
		duration = time.time() - now
		bp = c.fetchall()

		doc.startElement("periods", { "type": view.period_type, "query_time": str(duration) })

		pos = 0
		for period in view.periods:
			attrs = { "name": u"–".join(filter(None, [period.start_name, period.end_name])) }
			attrs["from"] = period.start_ts.isoformat()
			attrs["to"] = period.end_ts.isoformat()

			if len(bp) > pos and bp[pos]["start"] == period.start_ts:
				if bp[pos]["rx_bytes"] is not None:
					attrs["rx_bytes"] = str(bp[pos]["rx_bytes"])
				if bp[pos]["tx_bytes"] is not None:
					attrs["tx_bytes"] = str(bp[pos]["tx_bytes"])
				pos += 1

			doc.startElement("period", attrs)
			doc.endElement("period")

		doc.endElement("periods")

		c.close()
		db.commit()
	finally:
		pool.putconn(db)
	doc.endElement("usage")

def application(environ, start_response):
	req = webob.Request(environ)
	res = webob.Response(content_type="application/xml")

	uri = req.environ["REQUEST_URI"]

	f = res.body_file
	doc = XMLGenerator(f, "UTF-8")
	doc.startDocument()
#	f.write('<?xml-stylesheet type="text/xsl" href="traffic.xsl"?>\n'.encode("UTF-8"))
	doc.startElement("traffic", {})
	output_usage(doc, View(uri))
	doc.endElement("traffic")

	return res(environ, start_response)
