# coding: utf8
from xml.sax.saxutils import XMLGenerator
from datetime import datetime, timedelta
import collections
import psycopg2.extras
import psycopg2.pool
import pytz
import re
import time
import tzlocal
import webob
import webob.exc
import yaml

with open("config", "r") as f:
	config = yaml.safe_load(f)

tz = tzlocal.get_localzone()
date_re = re.compile(r"[0-9]*")

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

Period = collections.namedtuple("Period", ["start_name", "end_name", "short_name", "start_ts", "end_ts", "uri"])

class View:
	def __init__(self, req):
		self.device = config["device"]
		self.mode = req.GET.get("mode", "normal")

		uri = req.environ["REQUEST_URI"].split("?")[0]
		uri = uri[1:].split("/")
		if len(uri) == 1:
			self.date = uri[0]
		elif len(uri) == 2 and uri[0]:
			self.device = uri[0]
			self.date = uri[1]
		else:
			raise webob.exc.HTTPNotFound("Invalid URI")

		if len(self.date) not in [0, 4, 6, 8] or not date_re.match(self.date):
			raise webob.exc.HTTPNotFound("Invalid date format")

		if self.mode not in ["normal"]:
			raise webob.exc.HTTPNotFound("Invalid mode")

		if not self.date:
			self.date = "{0:04d}".format(datetime.now().year)

		self.periods = []
		self.parent = {}
		base_uri = "/" + self.device + "/" if len(uri) >= 2 else "/"

		if len(self.date) == 4:
			self.period_type = "Month"
			year = int(self.date)
			self.name = "{0:04d}".format(year)
			for month in range(1, 13):
				local_start = tz.localize(datetime(year, month, 1))
				local_end = tz.localize(datetime(year if month < 12 else year + 1, month + 1 if month < 12 else 1, 1))
				self.periods.append(Period(local_start.strftime("%B"), None, local_start.strftime("%b"), local_start, local_end, "{0}{1:04d}{2:02d}".format(base_uri, year, local_start.month)))
		elif len(self.date) == 6:
			self.period_type = "Day"
			year = int(self.date[0:4])
			month = int(self.date[4:6])
			self.name = "{0:04d}-{1:02d}".format(year, month)
			self.parent = { "name": "{0:04d}".format(year), "uri": "{0}{1:04d}".format(base_uri, year) }
			start = datetime(year, month, 1)
			end = datetime(year if month < 12 else year + 1, month + 1 if month < 12 else 1, 1)
			while start < end:
				local_start = tz.localize(start)
				local_end = tz.localize(start + timedelta(days=1))
				self.periods.append(Period(local_start.strftime("%d"), None, None, local_start, local_end, "{0}{1:04d}{2:02d}{3:02d}".format(base_uri, year, month, local_start.day)))
				start += timedelta(days=1)
		elif len(self.date) == 8:
			self.period_type = "Hour"
			year = int(self.date[0:4])
			month = int(self.date[4:6])
			day = int(self.date[6:8])
			self.name = "{0:04d}-{1:02d}-{2:02d}".format(year, month, day)
			self.parent = { "name": "{0:04d}-{1:02d}".format(year, month), "uri": "{0}{1:04d}{2:02d}".format(base_uri, year, month) }
			start = tz.localize(datetime(year, month, day)).astimezone(pytz.utc)
			end = datetime(year, month, day) + timedelta(days=1)
			while start.astimezone(tz).replace(tzinfo=None) < end:
				local_start = start.astimezone(tz)
				local_end = (start + timedelta(hours=1)).astimezone(tz)
				self.periods.append(Period(local_start.strftime("%H:%M"), (local_start + timedelta(hours=1, milliseconds=-1)).strftime("%H:%M"), local_start.strftime("%H"), local_start, local_end, None))
				start += timedelta(hours=1)

class Usage:
	def __init__(self, view):
		self.view = view
		db = getconn(pool, max_pool)
		try:
			c = db.cursor()

			start_periods = [period.start_ts for period in view.periods]
			end_periods = [period.end_ts for period in view.periods]
			now = time.time()
			c.execute("SELECT id FROM intf_name WHERE name=%s", (view.device,))
			if not c.rowcount:
				raise webob.exc.HTTPNotFound("No such device")
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
			self.query_time = time.time() - now
			self.bp = c.fetchall()

			c.close()
			db.commit()
		finally:
			pool.putconn(db)

	def output(self, doc):
		query_string = "" if self.view.mode == "normal" else "?mode=" + self.view.mode

		doc.startElement("usage", { "name": self.view.name })
		if self.view.parent:
			doc.startElement("parent", { "name": self.view.parent["name"], "uri": self.view.parent["uri"] + query_string })
			doc.endElement("parent")

		doc.startElement("periods", { "type": self.view.period_type, "query_time": str(self.query_time) })
		pos = 0
		for period in self.view.periods:
			attrs = { "name": u"–".join(filter(None, [period.start_name, period.end_name])) }
			if period.short_name:
				attrs["short_name"] = period.short_name
			if period.uri:
				attrs["uri"] = period.uri + query_string
			attrs["from"] = period.start_ts.isoformat()
			attrs["to"] = period.end_ts.isoformat()

			if len(self.bp) > pos and self.bp[pos]["start"] == period.start_ts:
				if self.bp[pos]["rx_bytes"] is not None:
					attrs["rx_bytes"] = str(self.bp[pos]["rx_bytes"])
				if self.bp[pos]["tx_bytes"] is not None:
					attrs["tx_bytes"] = str(self.bp[pos]["tx_bytes"])
				pos += 1

			doc.startElement("period", attrs)
			doc.endElement("period")

		doc.endElement("periods")
		doc.endElement("usage")

def application(environ, start_response):
	try:
		req = webob.Request(environ)
		res = webob.Response(content_type="application/xml")
		usage = Usage(View(req))

		f = res.body_file
		doc = XMLGenerator(f, "UTF-8")
		doc.startDocument()
		f.write('<?xml-stylesheet type="text/xsl" href="/traffic.xsl"?>\n'.encode("UTF-8"))
		doc.startElement("traffic", {})
		usage.output(doc)
		doc.endElement("traffic")

		return res(environ, start_response)
	except webob.exc.HTTPException, e:
		return e(environ, start_response)
