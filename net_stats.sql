--
-- PostgreSQL database dump
--

-- Dumped from database version 10.17 (Ubuntu 10.17-0ubuntu0.18.04.1)
-- Dumped by pg_dump version 10.17 (Ubuntu 10.17-0ubuntu0.18.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bp_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bp_stats (
    intf integer NOT NULL,
    start timestamp with time zone NOT NULL,
    stop timestamp with time zone NOT NULL,
    rx_bytes bigint NOT NULL,
    tx_bytes bigint NOT NULL,
    rx_packets bigint NOT NULL,
    tx_packets bigint NOT NULL
);


--
-- Name: dsl_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dsl_stats (
    modem integer NOT NULL,
    ts timestamp with time zone DEFAULT now() NOT NULL,
    status text NOT NULL,
    type integer NOT NULL,
    rx_rate integer NOT NULL,
    rx_max_rate integer,
    rx_att double precision,
    rx_snr double precision,
    rx_power double precision,
    tx_rate integer NOT NULL,
    tx_max_rate integer,
    tx_att double precision,
    tx_snr double precision,
    tx_power double precision,
    uptime bigint
);


--
-- Name: dsl_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dsl_type (
    id integer NOT NULL,
    name text NOT NULL
);


--
-- Name: dsl_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dsl_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dsl_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dsl_type_id_seq OWNED BY public.dsl_type.id;


--
-- Name: intf_name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intf_name (
    id integer NOT NULL,
    name text NOT NULL
);


--
-- Name: if_name_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.if_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: if_name_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.if_name_id_seq OWNED BY public.intf_name.id;


--
-- Name: modem_name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modem_name (
    id integer NOT NULL,
    name text NOT NULL
);


--
-- Name: modem_name_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.modem_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: modem_name_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.modem_name_id_seq OWNED BY public.modem_name.id;


--
-- Name: dsl_type id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dsl_type ALTER COLUMN id SET DEFAULT nextval('public.dsl_type_id_seq'::regclass);


--
-- Name: intf_name id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intf_name ALTER COLUMN id SET DEFAULT nextval('public.if_name_id_seq'::regclass);


--
-- Name: modem_name id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modem_name ALTER COLUMN id SET DEFAULT nextval('public.modem_name_id_seq'::regclass);


--
-- Name: bp_stats bp_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bp_stats
    ADD CONSTRAINT bp_stats_pkey PRIMARY KEY (intf, start);


--
-- Name: dsl_stats dsl_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dsl_stats
    ADD CONSTRAINT dsl_stats_pkey PRIMARY KEY (modem, ts);


--
-- Name: dsl_type dsl_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dsl_type
    ADD CONSTRAINT dsl_type_pkey PRIMARY KEY (id);


--
-- Name: intf_name if_name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intf_name
    ADD CONSTRAINT if_name_pkey PRIMARY KEY (id);


--
-- Name: modem_name modem_name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modem_name
    ADD CONSTRAINT modem_name_pkey PRIMARY KEY (id);


--
-- Name: bp_stats_intf_stop; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bp_stats_intf_stop ON public.bp_stats USING btree (intf, stop);


--
-- Name: bp_stats bp_stats_intf_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bp_stats
    ADD CONSTRAINT bp_stats_intf_fkey FOREIGN KEY (intf) REFERENCES public.intf_name(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dsl_stats dsl_stats_modem_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dsl_stats
    ADD CONSTRAINT dsl_stats_modem_fkey FOREIGN KEY (modem) REFERENCES public.modem_name(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dsl_stats dsl_stats_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dsl_stats
    ADD CONSTRAINT dsl_stats_type_fkey FOREIGN KEY (type) REFERENCES public.dsl_type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

