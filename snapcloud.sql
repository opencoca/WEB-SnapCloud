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
3	play with the BALL	t	t	Simulating a cat chasing a ball is so fun!\n\nUse the color slider to change your cat's color.	2023-12-17 19:57:08+00	2023-12-17 19:57:37+00	2023-12-17 19:57:26+00	mcat2000	2023-12-17 19:57:32+00	\N
1	asteroidz - landscape	t	t	Asteroidz is our take on the classic space shooter	2023-12-14 17:05:29+00	2023-12-18 12:21:16+00	2023-12-14 17:05:51+00	outofpaper	2023-12-14 17:05:56+00	\N
2	Binary Counter	t	t	An example of working with Binary counters	2023-12-17 19:47:56+00	2023-12-18 13:34:42+00	2023-12-17 19:48:09+00	outofpaper	2023-12-18 13:34:37+00	\N
4	space fight	t	t	fight your enemies in space	2023-12-18 16:24:31+00	2023-12-19 13:16:02+00	2023-12-18 16:27:30+00	mcat2000	2023-12-18 16:27:34+00	\N
5	HTML Blocks	t	t	An example of working with HTML elements. We add an element we call our WebApp. After this we add the styling for a simple row and column system and then populate it with some example content.	2023-12-19 13:36:08+00	2023-12-19 13:36:37+00	2023-12-19 13:36:17+00	outofpaper	2023-12-19 13:36:37+00	\N
6	canons	t	t	avoid rocks and shoot your friends.	2023-12-19 13:50:28+00	2023-12-19 13:51:19+00	2023-12-19 13:51:14+00	mcat2000	2023-12-19 13:51:19+00	\N
8	the time game show	t	t	gain and lose points based on time and acurisy	2023-12-20 10:01:59+00	2023-12-20 10:06:43+00	2023-12-20 10:02:10+00	mcat2000	2023-12-20 10:02:13+00	\N
9	Sound and Vision	t	t	An example of working with pen colors, sound, and the launch block.	2023-12-20 11:31:38+00	2023-12-20 11:33:39+00	2023-12-20 11:33:36+00	outofpaper	2023-12-20 11:33:39+00	\N
10	size and whiet	t	t		2023-12-21 09:52:59+00	2023-12-21 09:53:15+00	2023-12-21 09:53:12+00	mcat2000	2023-12-21 09:53:15+00	\N
12	RIAC Sound Levels	t	t	Created By Li and Ben. This application explores looking at sound levels and clones.	2023-12-21 13:09:04+00	2023-12-21 13:11:41+00	2023-12-21 13:10:32+00	outofpaper	2023-12-21 13:10:35+00	\N
13	beat jumper	t	t		2023-12-21 13:10:26+00	2023-12-22 12:42:27+00	2023-12-21 13:11:10+00	mcat2000	2023-12-21 13:11:14+00	\N
7	AI Development 001	t	t	This is a sneak peek into the brain(s) of AI.\n\nBrains are like parties. Connections are made and information is exchanged.\n\nThink of it as a social party where each of the colorful spheres is a guest. We’ve got a someone in blue, pink, yellow, green, and purple, all mingling through these orange lines that are the conversations happening between them.\n\nBrains be they real or virtual also connect in a simular fasion. Instead of people brains have neurons. Imagine each sphere as a neuron inside an AI's neural network. \n\nThose lines? They're the digital chit-chat—data zipping back and forth. Now, if you're diving into AI development, this is your bread and butter. You're the host of this shindig, and it's your job to make sure these guests connect, share info, and learn from each other.\n\nKeep this picture in mind when you're designing learning experiences. Each connection represents potential growth, a pathway to learning something new. And remember, just like in a real network, the strength of the connection matters. Weak connections? They're like those forgettable small talks. Strong connections are your deep, memorable conversations.\n\nNext time you're piecing together an AI, think about these vibrant little spheres. Your goal? To create those strong, meaningful links that turn a casual meet-up into a transformative gathering. Keep it colorful, keep it connected, and watch the magic happen!	2023-12-19 18:22:46+00	2023-12-23 18:41:42+00	2023-12-19 18:22:52+00	outofpaper	2023-12-19 18:22:55+00	\N
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
2023-12-20 10:03:06	izzyplante	verify_user	b39e8150162309c7f08d881d4ca10345445b8b9a1a2a0e1832e35280865aab764fc35d84e5ac4f2ff213e8aa65cbd87a5b9e4fcfd2881025964956cf7b7cca87
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, created, username, email, salt, password, about, location, verified, role, deleted, unique_email, bad_flags, is_teacher, creator_id) FROM stdin;
519956	\N	snapcloud	\N	\N	\N	\N	\N	t	admin	\N	\N	0	f	\N
2	2023-12-17 19:56:18+00	mcat2000	malcolm.somma@gmail.com	474db717ffb04ff86ce18837f1080920	edfe0ab37f934f2bd7004d710c96a44c514716e3a9e8f191f79d839e9882dbb192a220e3504e37f9a986393f59368daf6a5b931c50160a1ff85a5208de2013c0	\N	\N	t	standard	\N	\N	0	f	\N
1	2023-12-14 16:57:55+00	outofpaper	alexander.somma@gmail.com	474db717ffb04ff86ce18837f1080920	edfe0ab37f934f2bd7004d710c96a44c514716e3a9e8f191f79d839e9882dbb192a220e3504e37f9a986393f59368daf6a5b931c50160a1ff85a5208de2013c0	\N	\N	t	admin	\N	\N	0	t	\N
3	2023-12-20 10:03:06+00	izzyplante	izzy.plante@gmail.com	a150936aa5e5facffbd914268d12b6f5	0c5e6798433c8df3a4768f026fc138a5546f555cf9a72eb47bf1b3213540f495f95afc836e1896f1e9c16516ce756eb6dba62339bd140f60487659fb0476ded6	\N	\N	t	standard	\N	\N	0	f	\N
4	2023-12-20 14:09:31+00	aliogas	aliogas@thestudy.qc.ca	6004fafbabfc762b946c865db416fe43	20cbd5a16a27ef8c04433ebd922117523a72e64aee1e6e89fd8216a6fd2fb9399b85d9554cf235fa8c394caeeac3e13f165c23759b24fa80f8313c510971679e	\N	\N	t	standard	\N	\N	0	t	\N
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

SELECT pg_catalog.setval('public.projects_id_seq', 13, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 4, true);


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

