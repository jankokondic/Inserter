--
-- PostgreSQL database dump
--

\restrict Gp4wAEyKD1B7ibaOUCuViIeq4yXk1plLpSpOlKjICMyO4fmfIiaWWIOGYxwX4HL

-- Dumped from database version 16.12 (Debian 16.12-1.pgdg13+1)
-- Dumped by pg_dump version 16.12 (Debian 16.12-1.pgdg13+1)

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
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: billing_period; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.billing_period AS ENUM (
    'MONTHLY',
    'YEARLY'
);


ALTER TYPE public.billing_period OWNER TO nivoru;

--
-- Name: payment_status; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.payment_status AS ENUM (
    'PAID',
    'FAILED',
    'REFUNDED'
);


ALTER TYPE public.payment_status OWNER TO nivoru;

--
-- Name: price_adjustment_type; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.price_adjustment_type AS ENUM (
    'PERCENT_DISCOUNT',
    'AMOUNT_DISCOUNT',
    'FIXED_PRICE'
);


ALTER TYPE public.price_adjustment_type OWNER TO nivoru;

--
-- Name: schedule_exception_type; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.schedule_exception_type AS ENUM (
    'CLOSED',
    'CUSTOM_HOURS'
);


ALTER TYPE public.schedule_exception_type OWNER TO nivoru;

--
-- Name: service_color; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.service_color AS ENUM (
    'GRAY',
    'BLUE',
    'GREEN',
    'YELLOW',
    'ORANGE',
    'RED',
    'PURPLE',
    'PINK',
    'BROWN'
);


ALTER TYPE public.service_color OWNER TO nivoru;

--
-- Name: subscription_status; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.subscription_status AS ENUM (
    'ACTIVE',
    'PAST_DUE',
    'CANCELED'
);


ALTER TYPE public.subscription_status OWNER TO nivoru;

--
-- Name: user_status; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.user_status AS ENUM (
    'ACTIVE',
    'BANNED',
    'DELETED'
);


ALTER TYPE public.user_status OWNER TO nivoru;

--
-- Name: visit_status; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.visit_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'COMPLETED',
    'CANCELLED',
    'NO_SHOW'
);


ALTER TYPE public.visit_status OWNER TO nivoru;

--
-- Name: weekday_enum; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.weekday_enum AS ENUM (
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN'
);


ALTER TYPE public.weekday_enum OWNER TO nivoru;

--
-- Name: worker_availability_type; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.worker_availability_type AS ENUM (
    'WEEKLY_TEMPLATE',
    'ONE_OFF_SHIFT'
);


ALTER TYPE public.worker_availability_type OWNER TO nivoru;

--
-- Name: worker_role; Type: TYPE; Schema: public; Owner: nivoru
--

CREATE TYPE public.worker_role AS ENUM (
    'OWNER',
    'ADMIN',
    'WORKER'
);


ALTER TYPE public.worker_role OWNER TO nivoru;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: additional_information; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.additional_information (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    icon text
);


ALTER TABLE public.additional_information OWNER TO nivoru;

--
-- Name: additional_information_business; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.additional_information_business (
    additional_information_id uuid NOT NULL,
    business_id uuid NOT NULL
);


ALTER TABLE public.additional_information_business OWNER TO nivoru;

--
-- Name: barbershop_client_profile; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.barbershop_client_profile (
    business_client_id uuid NOT NULL,
    picture text,
    comment text,
    money_generated integer DEFAULT 0 NOT NULL,
    like_to_come time without time zone
);


ALTER TABLE public.barbershop_client_profile OWNER TO nivoru;

--
-- Name: business; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.business (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    location_id uuid,
    number_of_votes integer DEFAULT 0 NOT NULL,
    longitude double precision,
    latitude double precision,
    type text,
    about text,
    local_currency text,
    average_mark double precision
);


ALTER TABLE public.business OWNER TO nivoru;

--
-- Name: business_client; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.business_client (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    business_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.business_client OWNER TO nivoru;

--
-- Name: business_schedule_exception; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.business_schedule_exception (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    starts_at timestamp without time zone NOT NULL,
    ends_at timestamp without time zone NOT NULL,
    type public.schedule_exception_type NOT NULL,
    open_time time without time zone,
    close_time time without time zone,
    break_start time without time zone,
    break_end time without time zone,
    reason text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_bse_time CHECK ((ends_at > starts_at))
);


ALTER TABLE public.business_schedule_exception OWNER TO nivoru;

--
-- Name: business_subscription; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.business_subscription (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    plan_id uuid NOT NULL,
    billing_period public.billing_period NOT NULL,
    payer_user_id uuid,
    status public.subscription_status DEFAULT 'ACTIVE'::public.subscription_status NOT NULL,
    current_period_start timestamp without time zone,
    current_period_end timestamp without time zone,
    auto_renew boolean DEFAULT true NOT NULL,
    provider text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.business_subscription OWNER TO nivoru;

--
-- Name: business_working_hours; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.business_working_hours (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    day public.weekday_enum NOT NULL,
    is_closed boolean DEFAULT false NOT NULL,
    open_time time without time zone,
    close_time time without time zone,
    break_start time without time zone,
    break_end time without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_bwh_times CHECK (((is_closed = true) OR ((open_time IS NOT NULL) AND (close_time IS NOT NULL) AND (close_time > open_time) AND ((break_start IS NULL) OR (break_end IS NULL) OR (break_end > break_start)))))
);


ALTER TABLE public.business_working_hours OWNER TO nivoru;

--
-- Name: client_service_variant; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.client_service_variant (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_client_id uuid NOT NULL,
    service_id uuid NOT NULL,
    name_of_service text NOT NULL,
    photo text,
    notes text,
    average_duration_minutes integer,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.client_service_variant OWNER TO nivoru;

--
-- Name: gallery; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.gallery (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    url text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    size integer,
    width integer,
    height integer,
    is_cover boolean DEFAULT false NOT NULL,
    type text
);


ALTER TABLE public.gallery OWNER TO nivoru;

--
-- Name: location; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.location (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    country text,
    street_number integer,
    street text
);


ALTER TABLE public.location OWNER TO nivoru;

--
-- Name: payment; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.payment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid,
    business_id uuid NOT NULL,
    payer_user_id uuid,
    period_start timestamp without time zone,
    period_end timestamp without time zone,
    base_price_cents integer DEFAULT 0 NOT NULL,
    adjustment_amount_cents integer DEFAULT 0 NOT NULL,
    final_price_cents integer DEFAULT 0 NOT NULL,
    currency text NOT NULL,
    status public.payment_status DEFAULT 'PAID'::public.payment_status NOT NULL,
    paid_at timestamp without time zone,
    provider_payment_id text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.payment OWNER TO nivoru;

--
-- Name: payment_adjustment_applied; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.payment_adjustment_applied (
    payment_id uuid NOT NULL,
    rule_id uuid NOT NULL,
    type public.price_adjustment_type NOT NULL,
    value integer NOT NULL,
    amount_cents integer NOT NULL
);


ALTER TABLE public.payment_adjustment_applied OWNER TO nivoru;

--
-- Name: plan_price; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.plan_price (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_plan_id uuid NOT NULL,
    country_code text,
    currency text NOT NULL,
    billing_period public.billing_period NOT NULL,
    price_cents integer NOT NULL,
    tax_included boolean DEFAULT false NOT NULL,
    valid_from timestamp without time zone DEFAULT now() NOT NULL,
    valid_to timestamp without time zone
);


ALTER TABLE public.plan_price OWNER TO nivoru;

--
-- Name: price_adjustment_rule; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.price_adjustment_rule (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid,
    country_code text,
    billing_period public.billing_period,
    business_id uuid,
    type public.price_adjustment_type NOT NULL,
    value integer NOT NULL,
    valid_from timestamp without time zone DEFAULT now() NOT NULL,
    valid_to timestamp without time zone,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.price_adjustment_rule OWNER TO nivoru;

--
-- Name: review; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.review (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    rating integer NOT NULL,
    comment text,
    user_id uuid NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    status text
);


ALTER TABLE public.review OWNER TO nivoru;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO nivoru;

--
-- Name: service; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.service (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category text,
    business_id uuid NOT NULL,
    name text NOT NULL,
    color public.service_color,
    duration integer NOT NULL,
    price integer NOT NULL
);


ALTER TABLE public.service OWNER TO nivoru;

--
-- Name: subscription_plan; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.subscription_plan (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.subscription_plan OWNER TO nivoru;

--
-- Name: user; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public."user" (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text,
    avatar text,
    password_hash text,
    email text,
    phone_number text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    registration_way text,
    status public.user_status DEFAULT 'ACTIVE'::public.user_status NOT NULL,
    location_id uuid,
    language text
);


ALTER TABLE public."user" OWNER TO nivoru;

--
-- Name: visit; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.visit (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    business_id uuid NOT NULL,
    business_client_id uuid NOT NULL,
    worker_id uuid NOT NULL,
    started_at timestamp without time zone,
    end_at timestamp without time zone,
    status public.visit_status DEFAULT 'PENDING'::public.visit_status NOT NULL,
    note text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_visit_time CHECK ((((started_at IS NULL) AND (end_at IS NULL)) OR ((started_at IS NOT NULL) AND (end_at IS NOT NULL) AND (end_at > started_at))))
);


ALTER TABLE public.visit OWNER TO nivoru;

--
-- Name: visit_service_item; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.visit_service_item (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    visit_id uuid NOT NULL,
    service_id uuid NOT NULL,
    client_service_variant_id uuid,
    note text,
    started_at time without time zone,
    end_at time without time zone,
    price_snapshot integer NOT NULL,
    real_duration_of_service integer NOT NULL,
    CONSTRAINT chk_vsi_times CHECK ((((started_at IS NULL) AND (end_at IS NULL)) OR ((started_at IS NOT NULL) AND (end_at IS NOT NULL) AND (end_at > started_at))))
);


ALTER TABLE public.visit_service_item OWNER TO nivoru;

--
-- Name: worker; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.worker (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role public.worker_role DEFAULT 'WORKER'::public.worker_role NOT NULL,
    user_id uuid NOT NULL,
    business_id uuid NOT NULL,
    is_working boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    picture text
);


ALTER TABLE public.worker OWNER TO nivoru;

--
-- Name: worker_availability; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.worker_availability (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    worker_id uuid NOT NULL,
    business_id uuid NOT NULL,
    type public.worker_availability_type NOT NULL,
    weekday public.weekday_enum,
    date date,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_worker_availability_time CHECK ((end_time > start_time)),
    CONSTRAINT chk_worker_availability_type_fields CHECK ((((type = 'WEEKLY_TEMPLATE'::public.worker_availability_type) AND (weekday IS NOT NULL) AND (date IS NULL)) OR ((type = 'ONE_OFF_SHIFT'::public.worker_availability_type) AND (date IS NOT NULL) AND (weekday IS NULL))))
);


ALTER TABLE public.worker_availability OWNER TO nivoru;

--
-- Name: worker_service; Type: TABLE; Schema: public; Owner: nivoru
--

CREATE TABLE public.worker_service (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    worker_id uuid NOT NULL,
    service_id uuid NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.worker_service OWNER TO nivoru;

--
-- Data for Name: additional_information; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.additional_information (id, name, icon) FROM stdin;
\.


--
-- Data for Name: additional_information_business; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.additional_information_business (additional_information_id, business_id) FROM stdin;
\.


--
-- Data for Name: barbershop_client_profile; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.barbershop_client_profile (business_client_id, picture, comment, money_generated, like_to_come) FROM stdin;
\.


--
-- Data for Name: business; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.business (id, name, created_at, location_id, number_of_votes, longitude, latitude, type, about, local_currency, average_mark) FROM stdin;
\.


--
-- Data for Name: business_client; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.business_client (id, user_id, business_id, created_at) FROM stdin;
\.


--
-- Data for Name: business_schedule_exception; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.business_schedule_exception (id, business_id, starts_at, ends_at, type, open_time, close_time, break_start, break_end, reason, created_at) FROM stdin;
\.


--
-- Data for Name: business_subscription; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.business_subscription (id, business_id, plan_id, billing_period, payer_user_id, status, current_period_start, current_period_end, auto_renew, provider, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: business_working_hours; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.business_working_hours (id, business_id, day, is_closed, open_time, close_time, break_start, break_end, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: client_service_variant; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.client_service_variant (id, business_client_id, service_id, name_of_service, photo, notes, average_duration_minutes, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: gallery; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.gallery (id, business_id, url, created_at, size, width, height, is_cover, type) FROM stdin;
\.


--
-- Data for Name: location; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.location (id, country, street_number, street) FROM stdin;
\.


--
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.payment (id, subscription_id, business_id, payer_user_id, period_start, period_end, base_price_cents, adjustment_amount_cents, final_price_cents, currency, status, paid_at, provider_payment_id, created_at) FROM stdin;
\.


--
-- Data for Name: payment_adjustment_applied; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.payment_adjustment_applied (payment_id, rule_id, type, value, amount_cents) FROM stdin;
\.


--
-- Data for Name: plan_price; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.plan_price (id, subscription_plan_id, country_code, currency, billing_period, price_cents, tax_included, valid_from, valid_to) FROM stdin;
\.


--
-- Data for Name: price_adjustment_rule; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.price_adjustment_rule (id, plan_id, country_code, billing_period, business_id, type, value, valid_from, valid_to, priority, created_at) FROM stdin;
\.


--
-- Data for Name: review; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.review (id, business_id, rating, comment, user_id, updated_at, created_at, status) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.schema_migrations (version, dirty) FROM stdin;
14	f
\.


--
-- Data for Name: service; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.service (id, category, business_id, name, color, duration, price) FROM stdin;
\.


--
-- Data for Name: subscription_plan; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.subscription_plan (id, code, name, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public."user" (id, name, avatar, password_hash, email, phone_number, created_at, registration_way, status, location_id, language) FROM stdin;
\.


--
-- Data for Name: visit; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.visit (id, business_id, business_client_id, worker_id, started_at, end_at, status, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: visit_service_item; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.visit_service_item (id, visit_id, service_id, client_service_variant_id, note, started_at, end_at, price_snapshot, real_duration_of_service) FROM stdin;
\.


--
-- Data for Name: worker; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.worker (id, role, user_id, business_id, is_working, created_at, picture) FROM stdin;
\.


--
-- Data for Name: worker_availability; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.worker_availability (id, worker_id, business_id, type, weekday, date, start_time, end_time, created_at) FROM stdin;
\.


--
-- Data for Name: worker_service; Type: TABLE DATA; Schema: public; Owner: nivoru
--

COPY public.worker_service (id, worker_id, service_id, is_enabled, created_at) FROM stdin;
\.


--
-- Name: additional_information_business additional_information_business_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.additional_information_business
    ADD CONSTRAINT additional_information_business_pkey PRIMARY KEY (additional_information_id, business_id);


--
-- Name: additional_information additional_information_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.additional_information
    ADD CONSTRAINT additional_information_pkey PRIMARY KEY (id);


--
-- Name: barbershop_client_profile barbershop_client_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.barbershop_client_profile
    ADD CONSTRAINT barbershop_client_profile_pkey PRIMARY KEY (business_client_id);


--
-- Name: business_client business_client_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_client
    ADD CONSTRAINT business_client_pkey PRIMARY KEY (id);


--
-- Name: business business_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business
    ADD CONSTRAINT business_pkey PRIMARY KEY (id);


--
-- Name: business_schedule_exception business_schedule_exception_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_schedule_exception
    ADD CONSTRAINT business_schedule_exception_pkey PRIMARY KEY (id);


--
-- Name: business_subscription business_subscription_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_subscription
    ADD CONSTRAINT business_subscription_pkey PRIMARY KEY (id);


--
-- Name: business_working_hours business_working_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_working_hours
    ADD CONSTRAINT business_working_hours_pkey PRIMARY KEY (id);


--
-- Name: client_service_variant client_service_variant_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.client_service_variant
    ADD CONSTRAINT client_service_variant_pkey PRIMARY KEY (id);


--
-- Name: gallery gallery_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.gallery
    ADD CONSTRAINT gallery_pkey PRIMARY KEY (id);


--
-- Name: location location_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_pkey PRIMARY KEY (id);


--
-- Name: payment_adjustment_applied payment_adjustment_applied_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.payment_adjustment_applied
    ADD CONSTRAINT payment_adjustment_applied_pkey PRIMARY KEY (payment_id, rule_id);


--
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (id);


--
-- Name: plan_price plan_price_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.plan_price
    ADD CONSTRAINT plan_price_pkey PRIMARY KEY (id);


--
-- Name: price_adjustment_rule price_adjustment_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.price_adjustment_rule
    ADD CONSTRAINT price_adjustment_rule_pkey PRIMARY KEY (id);


--
-- Name: review review_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT review_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: service service_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (id);


--
-- Name: subscription_plan subscription_plan_code_key; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.subscription_plan
    ADD CONSTRAINT subscription_plan_code_key UNIQUE (code);


--
-- Name: subscription_plan subscription_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.subscription_plan
    ADD CONSTRAINT subscription_plan_pkey PRIMARY KEY (id);


--
-- Name: business_client uq_business_client_user_business; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_client
    ADD CONSTRAINT uq_business_client_user_business UNIQUE (user_id, business_id);


--
-- Name: business_working_hours uq_business_day; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_working_hours
    ADD CONSTRAINT uq_business_day UNIQUE (business_id, day);


--
-- Name: worker_service uq_worker_service; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker_service
    ADD CONSTRAINT uq_worker_service UNIQUE (worker_id, service_id);


--
-- Name: user user_email_key; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_email_key UNIQUE (email);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: visit visit_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_pkey PRIMARY KEY (id);


--
-- Name: visit_service_item visit_service_item_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.visit_service_item
    ADD CONSTRAINT visit_service_item_pkey PRIMARY KEY (id);


--
-- Name: worker_availability worker_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker_availability
    ADD CONSTRAINT worker_availability_pkey PRIMARY KEY (id);


--
-- Name: worker worker_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT worker_pkey PRIMARY KEY (id);


--
-- Name: worker_service worker_service_pkey; Type: CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker_service
    ADD CONSTRAINT worker_service_pkey PRIMARY KEY (id);


--
-- Name: idx_aib_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_aib_business ON public.additional_information_business USING btree (business_id);


--
-- Name: idx_bse_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_bse_business ON public.business_schedule_exception USING btree (business_id);


--
-- Name: idx_bse_range; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_bse_range ON public.business_schedule_exception USING btree (business_id, starts_at);


--
-- Name: idx_business_client_business_id; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_business_client_business_id ON public.business_client USING btree (business_id);


--
-- Name: idx_business_client_user_id; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_business_client_user_id ON public.business_client USING btree (user_id);


--
-- Name: idx_business_subscription_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_business_subscription_business ON public.business_subscription USING btree (business_id);


--
-- Name: idx_bwh_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_bwh_business ON public.business_working_hours USING btree (business_id);


--
-- Name: idx_csv_business_client; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_csv_business_client ON public.client_service_variant USING btree (business_client_id);


--
-- Name: idx_csv_service; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_csv_service ON public.client_service_variant USING btree (service_id);


--
-- Name: idx_gallery_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_gallery_business ON public.gallery USING btree (business_id);


--
-- Name: idx_par_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_par_business ON public.price_adjustment_rule USING btree (business_id);


--
-- Name: idx_par_plan; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_par_plan ON public.price_adjustment_rule USING btree (plan_id);


--
-- Name: idx_payment_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_payment_business ON public.payment USING btree (business_id);


--
-- Name: idx_payment_subscription; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_payment_subscription ON public.payment USING btree (subscription_id);


--
-- Name: idx_plan_price_plan; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_plan_price_plan ON public.plan_price USING btree (subscription_plan_id);


--
-- Name: idx_review_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_review_business ON public.review USING btree (business_id);


--
-- Name: idx_review_user; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_review_user ON public.review USING btree (user_id);


--
-- Name: idx_service_business_id; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_service_business_id ON public.service USING btree (business_id);


--
-- Name: idx_visit_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_visit_business ON public.visit USING btree (business_id);


--
-- Name: idx_visit_client; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_visit_client ON public.visit USING btree (business_client_id);


--
-- Name: idx_visit_worker_time; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_visit_worker_time ON public.visit USING btree (worker_id, started_at);


--
-- Name: idx_vsi_service; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_vsi_service ON public.visit_service_item USING btree (service_id);


--
-- Name: idx_vsi_variant; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_vsi_variant ON public.visit_service_item USING btree (client_service_variant_id);


--
-- Name: idx_vsi_visit; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_vsi_visit ON public.visit_service_item USING btree (visit_id);


--
-- Name: idx_worker_availability_business; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_worker_availability_business ON public.worker_availability USING btree (business_id);


--
-- Name: idx_worker_availability_date; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_worker_availability_date ON public.worker_availability USING btree (date);


--
-- Name: idx_worker_availability_worker; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_worker_availability_worker ON public.worker_availability USING btree (worker_id);


--
-- Name: idx_worker_business_id; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_worker_business_id ON public.worker USING btree (business_id);


--
-- Name: idx_worker_service_service; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_worker_service_service ON public.worker_service USING btree (service_id);


--
-- Name: idx_worker_service_worker; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_worker_service_worker ON public.worker_service USING btree (worker_id);


--
-- Name: idx_worker_user_id; Type: INDEX; Schema: public; Owner: nivoru
--

CREATE INDEX idx_worker_user_id ON public.worker USING btree (user_id);


--
-- Name: additional_information_business additional_information_business_additional_information_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.additional_information_business
    ADD CONSTRAINT additional_information_business_additional_information_id_fkey FOREIGN KEY (additional_information_id) REFERENCES public.additional_information(id) ON DELETE CASCADE;


--
-- Name: additional_information_business additional_information_business_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.additional_information_business
    ADD CONSTRAINT additional_information_business_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: barbershop_client_profile barbershop_client_profile_business_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.barbershop_client_profile
    ADD CONSTRAINT barbershop_client_profile_business_client_id_fkey FOREIGN KEY (business_client_id) REFERENCES public.business_client(id) ON DELETE CASCADE;


--
-- Name: business_client business_client_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_client
    ADD CONSTRAINT business_client_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: business_client business_client_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_client
    ADD CONSTRAINT business_client_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: business business_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business
    ADD CONSTRAINT business_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.location(id) ON DELETE SET NULL;


--
-- Name: business_schedule_exception business_schedule_exception_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_schedule_exception
    ADD CONSTRAINT business_schedule_exception_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: business_subscription business_subscription_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_subscription
    ADD CONSTRAINT business_subscription_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: business_subscription business_subscription_payer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_subscription
    ADD CONSTRAINT business_subscription_payer_user_id_fkey FOREIGN KEY (payer_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: business_subscription business_subscription_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_subscription
    ADD CONSTRAINT business_subscription_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.subscription_plan(id) ON DELETE RESTRICT;


--
-- Name: business_working_hours business_working_hours_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.business_working_hours
    ADD CONSTRAINT business_working_hours_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: client_service_variant client_service_variant_business_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.client_service_variant
    ADD CONSTRAINT client_service_variant_business_client_id_fkey FOREIGN KEY (business_client_id) REFERENCES public.business_client(id) ON DELETE CASCADE;


--
-- Name: client_service_variant client_service_variant_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.client_service_variant
    ADD CONSTRAINT client_service_variant_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(id) ON DELETE RESTRICT;


--
-- Name: gallery gallery_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.gallery
    ADD CONSTRAINT gallery_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: payment_adjustment_applied payment_adjustment_applied_payment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.payment_adjustment_applied
    ADD CONSTRAINT payment_adjustment_applied_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payment(id) ON DELETE CASCADE;


--
-- Name: payment_adjustment_applied payment_adjustment_applied_rule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.payment_adjustment_applied
    ADD CONSTRAINT payment_adjustment_applied_rule_id_fkey FOREIGN KEY (rule_id) REFERENCES public.price_adjustment_rule(id) ON DELETE SET NULL;


--
-- Name: payment payment_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: payment payment_payer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_payer_user_id_fkey FOREIGN KEY (payer_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: payment payment_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.business_subscription(id) ON DELETE SET NULL;


--
-- Name: plan_price plan_price_subscription_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.plan_price
    ADD CONSTRAINT plan_price_subscription_plan_id_fkey FOREIGN KEY (subscription_plan_id) REFERENCES public.subscription_plan(id) ON DELETE CASCADE;


--
-- Name: price_adjustment_rule price_adjustment_rule_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.price_adjustment_rule
    ADD CONSTRAINT price_adjustment_rule_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: price_adjustment_rule price_adjustment_rule_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.price_adjustment_rule
    ADD CONSTRAINT price_adjustment_rule_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.subscription_plan(id) ON DELETE CASCADE;


--
-- Name: review review_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT review_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: review review_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT review_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: service service_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: user user_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.location(id) ON DELETE SET NULL;


--
-- Name: visit visit_business_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_business_client_id_fkey FOREIGN KEY (business_client_id) REFERENCES public.business_client(id) ON DELETE CASCADE;


--
-- Name: visit visit_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: visit_service_item visit_service_item_client_service_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.visit_service_item
    ADD CONSTRAINT visit_service_item_client_service_variant_id_fkey FOREIGN KEY (client_service_variant_id) REFERENCES public.client_service_variant(id) ON DELETE SET NULL;


--
-- Name: visit_service_item visit_service_item_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.visit_service_item
    ADD CONSTRAINT visit_service_item_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(id) ON DELETE RESTRICT;


--
-- Name: visit_service_item visit_service_item_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.visit_service_item
    ADD CONSTRAINT visit_service_item_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visit(id) ON DELETE CASCADE;


--
-- Name: visit visit_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.visit
    ADD CONSTRAINT visit_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.worker(id) ON DELETE CASCADE;


--
-- Name: worker_availability worker_availability_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker_availability
    ADD CONSTRAINT worker_availability_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: worker_availability worker_availability_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker_availability
    ADD CONSTRAINT worker_availability_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.worker(id) ON DELETE CASCADE;


--
-- Name: worker worker_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT worker_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id) ON DELETE CASCADE;


--
-- Name: worker_service worker_service_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker_service
    ADD CONSTRAINT worker_service_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(id) ON DELETE CASCADE;


--
-- Name: worker_service worker_service_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker_service
    ADD CONSTRAINT worker_service_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.worker(id) ON DELETE CASCADE;


--
-- Name: worker worker_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nivoru
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT worker_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict Gp4wAEyKD1B7ibaOUCuViIeq4yXk1plLpSpOlKjICMyO4fmfIiaWWIOGYxwX4HL

