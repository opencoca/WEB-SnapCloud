--
-- PostgreSQL database dump
--

-- Dumped from database version 12.17 (Ubuntu 12.17-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.17 (Ubuntu 12.17-0ubuntu0.20.04.1)

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
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: dom_username; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.dom_username AS text;


ALTER DOMAIN public.dom_username OWNER TO postgres;

--
-- Name: snap_user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.snap_user_role AS ENUM (
    'student',
    'standard',
    'reviewer',
    'moderator',
    'admin',
    'banned'
);


ALTER TYPE public.snap_user_role OWNER TO postgres;

--
-- Name: expire_token(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.expire_token() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM tokens WHERE created < NOW() - INTERVAL '3 days';
RETURN NEW;
END;
$$;


ALTER FUNCTION public.expire_token() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    projectname text NOT NULL,
    ispublic boolean,
    ispublished boolean,
    notes text,
    created timestamp with time zone,
    lastupdated timestamp with time zone,
    lastshared timestamp with time zone,
    username public.dom_username NOT NULL,
    firstpublished timestamp with time zone,
    deleted timestamp with time zone
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: active_projects; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.active_projects AS
 SELECT projects.id,
    projects.projectname,
    projects.ispublic,
    projects.ispublished,
    projects.notes,
    projects.created,
    projects.lastupdated,
    projects.lastshared,
    projects.username,
    projects.firstpublished,
    projects.deleted
   FROM public.projects
  WHERE (projects.deleted IS NULL);


ALTER TABLE public.active_projects OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    created timestamp with time zone,
    username public.dom_username NOT NULL,
    email text,
    salt text,
    password text,
    about text,
    location text,
    verified boolean,
    role public.snap_user_role DEFAULT 'standard'::public.snap_user_role,
    deleted timestamp with time zone,
    unique_email text,
    bad_flags integer DEFAULT 0 NOT NULL,
    is_teacher boolean DEFAULT false NOT NULL,
    creator_id integer
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: active_users; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.active_users AS
 SELECT users.id,
    users.created,
    users.username,
    users.email,
    users.salt,
    users.password,
    users.about,
    users.location,
    users.verified,
    users.role,
    users.deleted,
    users.unique_email,
    users.bad_flags,
    users.is_teacher,
    users.creator_id
   FROM public.users
  WHERE (users.deleted IS NULL);


ALTER TABLE public.active_users OWNER TO postgres;

--
-- Name: banned_ips; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.banned_ips (
    ip text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    offense_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.banned_ips OWNER TO postgres;

--
-- Name: collection_memberships; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.collection_memberships (
    id integer NOT NULL,
    collection_id integer NOT NULL,
    project_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.collection_memberships OWNER TO postgres;

--
-- Name: collection_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.collection_memberships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.collection_memberships_id_seq OWNER TO postgres;

--
-- Name: collection_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.collection_memberships_id_seq OWNED BY public.collection_memberships.id;


--
-- Name: collections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.collections (
    id integer NOT NULL,
    name text NOT NULL,
    creator_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    description text,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone,
    shared boolean DEFAULT false NOT NULL,
    shared_at timestamp with time zone,
    thumbnail_id integer,
    editor_ids integer[],
    free_for_all boolean DEFAULT false NOT NULL
);


ALTER TABLE public.collections OWNER TO postgres;

--
-- Name: collections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.collections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.collections_id_seq OWNER TO postgres;

--
-- Name: collections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.collections_id_seq OWNED BY public.collections.id;


--
-- Name: count_recent_projects; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.count_recent_projects AS
 SELECT count(*) AS count
   FROM public.projects
  WHERE (projects.lastupdated > (('now'::text)::date - '1 day'::interval));


ALTER TABLE public.count_recent_projects OWNER TO postgres;

--
-- Name: deleted_projects; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.deleted_projects AS
 SELECT projects.id,
    projects.projectname,
    projects.ispublic,
    projects.ispublished,
    projects.notes,
    projects.created,
    projects.lastupdated,
    projects.lastshared,
    projects.username,
    projects.firstpublished,
    projects.deleted
   FROM public.projects
  WHERE (projects.deleted IS NOT NULL);


ALTER TABLE public.deleted_projects OWNER TO postgres;

--
-- Name: deleted_users; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.deleted_users AS
 SELECT users.id,
    users.created,
    users.username,
    users.email,
    users.salt,
    users.password,
    users.about,
    users.location,
    users.verified,
    users.role,
    users.deleted,
    users.unique_email,
    users.bad_flags,
    users.is_teacher,
    users.creator_id
   FROM public.users
  WHERE (users.deleted IS NOT NULL);


ALTER TABLE public.deleted_users OWNER TO postgres;

--
-- Name: featured_collections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.featured_collections (
    collection_id integer NOT NULL,
    page_path text NOT NULL,
    type text NOT NULL,
    "order" integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.featured_collections OWNER TO postgres;

--
-- Name: flagged_projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.flagged_projects (
    id integer NOT NULL,
    flagger_id integer NOT NULL,
    project_id integer NOT NULL,
    reason text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    notes text
);


ALTER TABLE public.flagged_projects OWNER TO postgres;

--
-- Name: flagged_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.flagged_projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.flagged_projects_id_seq OWNER TO postgres;

--
-- Name: flagged_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.flagged_projects_id_seq OWNED BY public.flagged_projects.id;


--
-- Name: followers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.followers (
    follower_id integer NOT NULL,
    followed_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.followers OWNER TO postgres;

--
-- Name: lapis_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lapis_migrations (
    name character varying(255) NOT NULL
);


ALTER TABLE public.lapis_migrations OWNER TO postgres;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_id_seq OWNER TO postgres;

--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: recent_projects_2_days; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.recent_projects_2_days AS
 SELECT count(*) AS count
   FROM public.projects
  WHERE (projects.lastupdated > (('now'::text)::date - '2 days'::interval));


ALTER TABLE public.recent_projects_2_days OWNER TO postgres;

--
-- Name: remixes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.remixes (
    original_project_id integer,
    remixed_project_id integer NOT NULL,
    created timestamp with time zone
);


ALTER TABLE public.remixes OWNER TO postgres;

--
-- Name: tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tokens (
    created timestamp without time zone DEFAULT now() NOT NULL,
    username public.dom_username NOT NULL,
    purpose text,
    value text NOT NULL
);


ALTER TABLE public.tokens OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: collection_memberships id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.collection_memberships ALTER COLUMN id SET DEFAULT nextval('public.collection_memberships_id_seq'::regclass);


--
-- Name: collections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.collections ALTER COLUMN id SET DEFAULT nextval('public.collections_id_seq'::regclass);


--
-- Name: flagged_projects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flagged_projects ALTER COLUMN id SET DEFAULT nextval('public.flagged_projects_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: banned_ips; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.banned_ips (ip, created_at, updated_at, offense_count) FROM stdin;
\.


--
-- Data for Name: collection_memberships; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.collection_memberships (id, collection_id, project_id, created_at, updated_at, user_id) FROM stdin;
\.


--
-- Data for Name: collections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.collections (id, name, creator_id, created_at, updated_at, description, published, published_at, shared, shared_at, thumbnail_id, editor_ids, free_for_all) FROM stdin;
0	Flagged	519956	2023-12-13 14:13:07.565057+00	2023-12-13 14:13:07.565057+00		f	\N	f	\N	\N	{}	f
4	Featured	519956	2023-12-13 14:13:07.565057+00	2023-12-13 14:13:07.565057+00	This is the collection from which the "Featured Projects" front page carousel feeds.	t	2023-12-13 14:13:07.565057+00	t	2023-12-13 14:13:07.565057+00	\N	{}	f
6	Games	519956	2023-12-13 14:13:07.565057+00	2023-12-13 14:13:07.565057+00	A collection of games curated by the Snap! team.	t	2023-12-13 14:13:07.565057+00	t	2023-12-13 14:13:07.565057+00	\N	{}	f
7	Fractals	519956	2023-12-13 14:13:07.565057+00	2023-12-13 14:13:07.565057+00	A collection of fractals curated by the Snap! team.	t	2023-12-13 14:13:07.565057+00	t	2023-12-13 14:13:07.565057+00	\N	{}	f
8	Art Projects	519956	2023-12-13 14:13:07.565057+00	2023-12-13 14:13:07.565057+00	A collection of art projects curated by the Snap! team.	t	2023-12-13 14:13:07.565057+00	t	2023-12-13 14:13:07.565057+00	\N	{}	f
9	Science Projects	519956	2023-12-13 14:13:07.565057+00	2023-12-13 14:13:07.565057+00	A collection of science-related projects curated by the Snap! team.	t	2023-12-13 14:13:07.565057+00	t	2023-12-13 14:13:07.565057+00	\N	{}	f
37	Animations	519956	2023-12-13 14:13:07.565057+00	2023-12-13 14:13:07.565057+00		t	2023-12-13 14:13:07.565057+00	t	2023-12-13 14:13:07.565057+00	\N	{}	f
67	Simulations	519956	2023-12-13 14:13:07.565057+00	2023-12-13 14:13:07.565057+00	Simulating real-world behavior in Snap!.	f	\N	f	\N	\N	{}	f
390	Snap!Con 2019	519956	2023-12-13 14:13:07.565057+00	2023-12-13 14:13:07.565057+00	Projects that we all demoed, shared or developed during Snap!Con 2019 in Heidelberg.	t	2023-12-13 14:13:07.565057+00	t	2023-12-13 14:13:07.565057+00	\N	{}	f
\.


--
-- Data for Name: featured_collections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.featured_collections (collection_id, page_path, type, "order", created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: flagged_projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.flagged_projects (id, flagger_id, project_id, reason, created_at, updated_at, notes) FROM stdin;
\.


--
-- Data for Name: followers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.followers (follower_id, followed_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: lapis_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lapis_migrations (name) FROM stdin;
20190140
201901291
20190141
2019-01-04:0
2019-01-29:0
2019-02-01:0
2019-02-05:0
2019-02-04:0
2020-10-22:0
2020-11-03:0
2020-11-09:0
2020-11-10:0
2022-08-16:0
2022-08-17:0
2022-08-18:0
2022-09-16:0
1683536418
2023-03-14:0
2023-03-14:1
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, projectname, ispublic, ispublished, notes, created, lastupdated, lastshared, username, firstpublished, deleted) FROM stdin;
1	asteroidz - landscape	t	t	Asteroidz is our take on the classic space shooter	2023-12-14 17:05:29+00	2023-12-14 17:16:49+00	2023-12-14 17:05:51+00	outofpaper	2023-12-14 17:05:56+00	\N
2	Binary Counter	t	f	An example of working with Binary counters	2023-12-17 19:47:56+00	2023-12-17 19:48:14+00	2023-12-17 19:48:09+00	outofpaper	\N	\N
3	play with the BALL	t	t	Simulating a cat chasing a ball is so fun!\n\nUse the color slider to change your cat's color.	2023-12-17 19:57:08+00	2023-12-17 19:57:37+00	2023-12-17 19:57:26+00	mcat2000	2023-12-17 19:57:32+00	\N
\.


--
-- Data for Name: remixes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.remixes (original_project_id, remixed_project_id, created) FROM stdin;
\.


--
-- Data for Name: tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tokens (created, username, purpose, value) FROM stdin;
2023-12-17 19:56:18	mcat2000	verify_user	d4c7f3788b83f496c8d4b8df9cc192d70a6ef93bf8b0fce4358cee0dea3a9392433269665b5c06212a4359cd4e10d90837e5e96965624edf0090f62d1d81ed4e
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, created, username, email, salt, password, about, location, verified, role, deleted, unique_email, bad_flags, is_teacher, creator_id) FROM stdin;
519956	\N	snapcloud	\N	\N	\N	\N	\N	t	admin	\N	\N	0	f	\N
1	2023-12-14 16:57:55+00	outofpaper	alexander.somma@gmail.com	474db717ffb04ff86ce18837f1080920	edfe0ab37f934f2bd7004d710c96a44c514716e3a9e8f191f79d839e9882dbb192a220e3504e37f9a986393f59368daf6a5b931c50160a1ff85a5208de2013c0	\N	\N	t	admin	\N	\N	0	f	\N
2	2023-12-17 19:56:18+00	mcat2000	malcolm.sooma@gmail.com	88649af1d0db2e937d1d1ac2ebc9451c	5b1d3a8975ceadeada8a5d698cfeefaa5aa2455f84e94a7185dbea5c8ff3ec080335ce792a936d2029eb230b0a05aeda4066a3e8c70b189e874b00a058c47e59	\N	\N	t	standard	\N	\N	0	f	\N
\.


--
-- Name: collection_memberships_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.collection_memberships_id_seq', 1, false);


--
-- Name: collections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.collections_id_seq', 1, false);


--
-- Name: flagged_projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.flagged_projects_id_seq', 1, false);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_id_seq', 3, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: banned_ips banned_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.banned_ips
    ADD CONSTRAINT banned_ips_pkey PRIMARY KEY (ip);


--
-- Name: collection_memberships collection_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.collection_memberships
    ADD CONSTRAINT collection_memberships_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: featured_collections featured_collections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.featured_collections
    ADD CONSTRAINT featured_collections_pkey PRIMARY KEY (collection_id, page_path);


--
-- Name: flagged_projects flagged_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flagged_projects
    ADD CONSTRAINT flagged_projects_pkey PRIMARY KEY (id);


--
-- Name: followers followers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (follower_id, followed_id);


--
-- Name: lapis_migrations lapis_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lapis_migrations
    ADD CONSTRAINT lapis_migrations_pkey PRIMARY KEY (name);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (username, projectname);


--
-- Name: projects unique_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT unique_id UNIQUE (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: users users_unique_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_unique_email_key UNIQUE (unique_email);


--
-- Name: tokens value_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT value_pkey PRIMARY KEY (value);


--
-- Name: collection_memberships_collection_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX collection_memberships_collection_id_idx ON public.collection_memberships USING btree (collection_id);


--
-- Name: collection_memberships_collection_id_project_id_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX collection_memberships_collection_id_project_id_user_id_idx ON public.collection_memberships USING btree (collection_id, project_id, user_id);


--
-- Name: collection_memberships_project_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX collection_memberships_project_id_idx ON public.collection_memberships USING btree (project_id);


--
-- Name: collections_creator_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX collections_creator_id_idx ON public.collections USING btree (creator_id);


--
-- Name: flagged_projects_flagger_id_project_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX flagged_projects_flagger_id_project_id_idx ON public.flagged_projects USING btree (flagger_id, project_id);


--
-- Name: original_project_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX original_project_id_index ON public.remixes USING btree (original_project_id);


--
-- Name: remixed_project_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX remixed_project_id_index ON public.remixes USING btree (remixed_project_id);


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_email_idx ON public.users USING btree (email);


--
-- Name: tokens expire_token_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER expire_token_trigger AFTER INSERT ON public.tokens FOR EACH STATEMENT EXECUTE FUNCTION public.expire_token();


--
-- Name: projects projects_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_username_fkey FOREIGN KEY (username) REFERENCES public.users(username) ON UPDATE CASCADE;


--
-- Name: remixes remixes_original_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.remixes
    ADD CONSTRAINT remixes_original_project_id_fkey FOREIGN KEY (original_project_id) REFERENCES public.projects(id);


--
-- Name: remixes remixes_remixed_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.remixes
    ADD CONSTRAINT remixes_remixed_project_id_fkey FOREIGN KEY (remixed_project_id) REFERENCES public.projects(id);


--
-- Name: tokens users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT users_fkey FOREIGN KEY (username) REFERENCES public.users(username) ON UPDATE CASCADE;


--
-- PostgreSQL database dump complete
--

