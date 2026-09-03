--
-- PostgreSQL database dump
--

\restrict QFgIlmYIkF0EfaetfaiXwrj5h8nxn8cnCXCg7sfsKcC6czBY6EwvhpQNCsGR232

-- Dumped from database version 17.11
-- Dumped by pg_dump version 17.11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alarm_profile_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alarm_profile_overrides (
    id text NOT NULL,
    profile_version_id text NOT NULL,
    rule_id text NOT NULL,
    override_type text NOT NULL,
    state_kind text,
    transition_key text,
    warning_after_minutes integer,
    alert_after_minutes integer,
    hysteresis_seconds integer,
    baseline_state text,
    severity text,
    closure_condition text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: alarm_profile_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alarm_profile_versions (
    id text NOT NULL,
    resident_id text NOT NULL,
    valid_from timestamp without time zone DEFAULT now() NOT NULL,
    valid_to timestamp without time zone,
    mobility_aid text,
    autopilot boolean DEFAULT false,
    mode text,
    template_id text,
    catalog_version text,
    updated_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    risk_level text DEFAULT 'medium'::text,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id text NOT NULL,
    actor_id text,
    action text NOT NULL,
    entity_type text NOT NULL,
    entity_id text NOT NULL,
    metadata_json text DEFAULT '{}'::text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: auth_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_sessions (
    token_hash bytea NOT NULL,
    user_id text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    last_seen_at timestamp without time zone
);


--
-- Name: bathroom_summaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bathroom_summaries (
    id text NOT NULL,
    source_record_id text NOT NULL,
    resident_id text NOT NULL,
    observed_on date NOT NULL,
    visit_count integer DEFAULT 0,
    night_visit_count integer DEFAULT 0,
    assisted_count integer DEFAULT 0,
    total_minutes integer DEFAULT 0,
    source text,
    model_version text,
    confidence real,
    provenance_json text DEFAULT '{}'::text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: beds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beds (
    id text NOT NULL,
    room_id text NOT NULL,
    label text NOT NULL,
    monitor_key text,
    retired_at text,
    retired_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: care_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.care_notes (
    id text NOT NULL,
    resident_id text NOT NULL,
    author_id text NOT NULL,
    kind text DEFAULT 'general'::text,
    body text NOT NULL,
    duration_min integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: care_summaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.care_summaries (
    id text NOT NULL,
    source_record_id text NOT NULL,
    resident_id text NOT NULL,
    observed_on date NOT NULL,
    total_minutes integer DEFAULT 0,
    proactive_minutes integer DEFAULT 0,
    rounds_count integer DEFAULT 0,
    notes_count integer DEFAULT 0,
    source text,
    model_version text,
    confidence real,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0
);


--
-- Name: clip_windows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clip_windows (
    window_id text NOT NULL,
    bed_id text NOT NULL,
    resident_id text NOT NULL,
    started_at timestamp without time zone NOT NULL,
    ended_at timestamp without time zone,
    timeout_minutes integer DEFAULT 5,
    events_json text DEFAULT '[]'::text,
    state text DEFAULT 'open'::text,
    close_condition_json text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    closed_at timestamp without time zone,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: current_bed_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_bed_states (
    bed_id text NOT NULL,
    resident_id text,
    room_state text,
    state text,
    substate text,
    sleeping boolean,
    state_since timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    source text,
    source_event_id text,
    staff_present boolean
);


--
-- Name: episode_escalations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.episode_escalations (
    id text NOT NULL,
    episode_id text NOT NULL,
    level integer NOT NULL,
    target_id text NOT NULL,
    occurred_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: episode_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.episode_notes (
    id text NOT NULL,
    episode_id text NOT NULL,
    author_id text NOT NULL,
    kind text NOT NULL,
    body text NOT NULL,
    "timestamp" text NOT NULL,
    created_at text DEFAULT now() NOT NULL,
    CONSTRAINT episode_notes_kind_check CHECK ((kind = ANY (ARRAY['ACKNOWLEDGEMENT'::text, 'RESOLUTION'::text, 'CLINICAL_NOTE'::text])))
);


--
-- Name: episode_timeline_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.episode_timeline_events (
    id character varying(36) NOT NULL,
    episode_id character varying(36) NOT NULL,
    resident_id character varying(36) NOT NULL,
    at timestamp without time zone NOT NULL,
    type character varying(30) NOT NULL,
    from_state character varying(50),
    to_state character varying(50),
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: episode_transitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.episode_transitions (
    id text NOT NULL,
    episode_id text NOT NULL,
    from_status text,
    to_status text NOT NULL,
    actor_id text NOT NULL,
    occurred_at timestamp without time zone NOT NULL,
    sequence integer NOT NULL
);


--
-- Name: episodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.episodes (
    id text NOT NULL,
    resident_id text NOT NULL,
    bed_id text,
    evidence_kind text,
    evidence_ref text,
    rule_id text,
    severity text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    status_actor_id text,
    status_at timestamp without time zone,
    title text,
    detail text,
    occurred_at timestamp without time zone NOT NULL,
    escalation_level integer DEFAULT 0,
    escalated_at timestamp without time zone,
    escalated_to text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: evidence; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evidence (
    id text NOT NULL,
    bed_id text NOT NULL,
    resident_id text NOT NULL,
    evidence_type text NOT NULL,
    category text,
    scene_event_id text,
    scene_event_json text,
    rule_id text,
    shift text,
    risk_level text,
    "timestamp" timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: facilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facilities (
    id text NOT NULL,
    name text NOT NULL,
    timezone text DEFAULT 'UTC'::text NOT NULL,
    retired_at text,
    retired_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: facility_shifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facility_shifts (
    id text NOT NULL,
    facility_id text NOT NULL,
    key text NOT NULL,
    label text NOT NULL,
    start_minute integer NOT NULL,
    sort_order integer DEFAULT 0,
    retired_at text,
    retired_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    CONSTRAINT facility_shifts_start_minute_check CHECK (((start_minute >= 0) AND (start_minute <= 1439)))
);


--
-- Name: history_episode_detections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.history_episode_detections (
    id text NOT NULL,
    source_record_id text NOT NULL,
    resident_id text NOT NULL,
    bed_id text,
    source_episode_id text,
    kind text NOT NULL,
    severity text NOT NULL,
    occurred_at timestamp without time zone NOT NULL,
    location text,
    activity text,
    injury_status text,
    self_recovery boolean DEFAULT false,
    response_seconds integer,
    narrative text,
    interventions_json text DEFAULT '[]'::text,
    source text NOT NULL,
    model_version text,
    confidence real,
    provenance_json text DEFAULT '{}'::text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: history_episode_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.history_episode_reviews (
    id text NOT NULL,
    episode_id text NOT NULL,
    status text NOT NULL,
    detection_verdict text,
    review_note text,
    resolved_at timestamp without time zone,
    actor_id text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: mobility_summaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mobility_summaries (
    id text NOT NULL,
    source_record_id text NOT NULL,
    resident_id text NOT NULL,
    observed_on date NOT NULL,
    in_bed_minutes integer DEFAULT 0,
    out_of_bed_minutes integer DEFAULT 0,
    out_of_sight_minutes integer DEFAULT 0,
    walking_minutes integer DEFAULT 0,
    distance_meters real DEFAULT 0,
    transfer_count integer DEFAULT 0,
    source text,
    model_version text,
    confidence real,
    provenance_json text DEFAULT '{}'::text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: notification_deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_deliveries (
    id text NOT NULL,
    episode_id text NOT NULL,
    recipient_kind text NOT NULL,
    recipient_id text NOT NULL,
    channel text NOT NULL,
    escalation_level integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: notification_delivery_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_delivery_events (
    id text NOT NULL,
    delivery_id text NOT NULL,
    kind text NOT NULL,
    reason text,
    occurred_at timestamp without time zone NOT NULL
);


--
-- Name: notification_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_events (
    id text NOT NULL,
    category text NOT NULL,
    bed_id text,
    resident_id text,
    event_type text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    rule_id text,
    risk_level text,
    payload_json text DEFAULT '{}'::text,
    received_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: planogram_placements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planogram_placements (
    id text NOT NULL,
    wing_id text NOT NULL,
    room_id text NOT NULL,
    x real NOT NULL,
    y real NOT NULL,
    sort_order integer DEFAULT 0,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: policy_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.policy_recommendations (
    id character varying(36) NOT NULL,
    episode_id character varying(36) NOT NULL,
    resident_id character varying(36) NOT NULL,
    title character varying(200) NOT NULL,
    description text NOT NULL,
    origin character varying(20) NOT NULL,
    state character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    patch_template_id character varying(50),
    patch_mode character varying(50),
    patch_risk_level character varying(20),
    patch_mobility_aid character varying(50),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    resolved_at timestamp without time zone,
    applied_at timestamp without time zone,
    patch_autopilot boolean
);


--
-- Name: resident_bed_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resident_bed_assignments (
    id text NOT NULL,
    resident_id text NOT NULL,
    bed_id text NOT NULL,
    starts_at timestamp without time zone NOT NULL,
    ends_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by text,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: resident_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resident_notes (
    id text NOT NULL,
    resident_id text NOT NULL,
    author_id text NOT NULL,
    kind text NOT NULL,
    body text NOT NULL,
    source_event_id text,
    "timestamp" text NOT NULL,
    created_at text DEFAULT now() NOT NULL,
    updated_at text DEFAULT now() NOT NULL,
    CONSTRAINT resident_notes_kind_check CHECK ((kind = ANY (ARRAY['CARE'::text, 'CLINICAL'::text, 'INSIGHT'::text, 'PATTERN'::text, 'OBSERVATION'::text, 'SUMMARY'::text])))
);


--
-- Name: resident_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resident_profiles (
    id text NOT NULL,
    resident_id text NOT NULL,
    profile_id text NOT NULL,
    version integer NOT NULL,
    supersedes integer,
    valid_from timestamp without time zone NOT NULL,
    provenance_json text DEFAULT '{}'::text NOT NULL,
    windows_json text DEFAULT '[]'::text NOT NULL,
    subjects_json text DEFAULT '{}'::text NOT NULL,
    raw_json text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: residents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.residents (
    id text NOT NULL,
    external_id text,
    full_name text NOT NULL,
    birth_date date,
    admission_date date NOT NULL,
    status text DEFAULT 'active'::text,
    discharged_at timestamp without time zone,
    discharged_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    CONSTRAINT residents_status_check CHECK ((status = ANY (ARRAY['active'::text, 'discharged'::text])))
);


--
-- Name: room_privacy_regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_privacy_regions (
    id text NOT NULL,
    room_id text NOT NULL,
    x real NOT NULL,
    y real NOT NULL,
    w real NOT NULL,
    h real NOT NULL,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rooms (
    id text NOT NULL,
    wing_id text NOT NULL,
    number text NOT NULL,
    room_type text,
    stream_key text,
    retired_at text,
    retired_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: round_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.round_tasks (
    id text NOT NULL,
    round_id text NOT NULL,
    resident_id text NOT NULL,
    bed_id text,
    status text DEFAULT 'pending'::text,
    note text,
    completed_at timestamp without time zone,
    completed_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    CONSTRAINT round_tasks_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text])))
);


--
-- Name: rounds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rounds (
    id text NOT NULL,
    wing_id text NOT NULL,
    status text DEFAULT 'in_progress'::text,
    scheduled_for timestamp without time zone,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    started_by text,
    completed_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    CONSTRAINT rounds_status_check CHECK ((status = ANY (ARRAY['in_progress'::text, 'completed'::text, 'cancelled'::text])))
);


--
-- Name: scene_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scene_events (
    id text NOT NULL,
    event_id text NOT NULL,
    bed_id text NOT NULL,
    resident_id text,
    event_type text NOT NULL,
    from_state text,
    to_state text,
    trigger_type text,
    "timestamp" timestamp without time zone NOT NULL,
    payload_json text DEFAULT '{}'::text,
    received_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: sensor_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensor_events (
    id text NOT NULL,
    source_event_id text NOT NULL,
    monitor_key text NOT NULL,
    bed_id text,
    resident_id text,
    kind text NOT NULL,
    room_state text,
    substate text,
    zone text,
    state text,
    sleeping boolean,
    occurred_at timestamp without time zone NOT NULL,
    received_at timestamp without time zone DEFAULT now() NOT NULL,
    payload_json text DEFAULT '{}'::text
);


--
-- Name: shift_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shift_notes (
    id text NOT NULL,
    facility_id text NOT NULL,
    wing_id text,
    shift_key text NOT NULL,
    shift_date text NOT NULL,
    author_id text NOT NULL,
    kind text NOT NULL,
    body text NOT NULL,
    "timestamp" text NOT NULL,
    created_at text DEFAULT now() NOT NULL,
    CONSTRAINT shift_notes_kind_check CHECK ((kind = ANY (ARRAY['SHIFT_SUMMARY'::text, 'INCIDENT_REPORT'::text, 'GENERAL'::text])))
);


--
-- Name: sleep_summaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sleep_summaries (
    id text NOT NULL,
    source_record_id text NOT NULL,
    resident_id text NOT NULL,
    observed_on date NOT NULL,
    calm_minutes integer DEFAULT 0,
    restless_minutes integer DEFAULT 0,
    awake_minutes integer DEFAULT 0,
    out_of_bed_minutes integer DEFAULT 0,
    bed_exit_count integer DEFAULT 0,
    wake_count integer DEFAULT 0,
    source text,
    model_version text,
    confidence real,
    provenance_json text DEFAULT '{}'::text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    started_at timestamp without time zone,
    ended_at timestamp without time zone
);


--
-- Name: staff_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_groups (
    id text NOT NULL,
    facility_id text NOT NULL,
    name text NOT NULL,
    retired_at text,
    retired_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: stream_regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stream_regions (
    id text NOT NULL,
    stream_id text NOT NULL,
    region_type text NOT NULL,
    points text NOT NULL,
    label text,
    is_static boolean DEFAULT true,
    updated_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    CONSTRAINT stream_regions_region_type_check CHECK ((region_type = ANY (ARRAY['bathroom'::text, 'hallway'::text, 'exit'::text, 'bed'::text, 'furniture'::text, 'person'::text, 'object'::text])))
);


--
-- Name: streams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.streams (
    id text NOT NULL,
    room_id text NOT NULL,
    stream_key text NOT NULL,
    name text,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: timelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timelines (
    id text NOT NULL,
    bed_id text NOT NULL,
    resident_id text NOT NULL,
    anchor_event_id text,
    anchor_event_json text,
    before_events_json text DEFAULT '[]'::text,
    after_events_json text DEFAULT '[]'::text,
    window_start timestamp without time zone NOT NULL,
    window_end timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    closed_at timestamp without time zone,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: unit_shift_coverages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unit_shift_coverages (
    id text NOT NULL,
    wing_id text NOT NULL,
    staff_group_id text NOT NULL,
    shift_key text NOT NULL,
    valid_from timestamp without time zone DEFAULT now() NOT NULL,
    valid_to timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by text
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id text NOT NULL,
    username text,
    display_name text,
    role text,
    job_title text,
    password_hash text,
    retired_at text,
    retired_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    CONSTRAINT users_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'supervisor'::text, 'staff'::text])))
);


--
-- Name: wings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wings (
    id text NOT NULL,
    facility_id text NOT NULL,
    name text NOT NULL,
    floor text,
    sort_order integer DEFAULT 0,
    retired_at text,
    retired_by text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0 NOT NULL
);


--
-- Name: alarm_profile_overrides alarm_profile_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alarm_profile_overrides
    ADD CONSTRAINT alarm_profile_overrides_pkey PRIMARY KEY (id);


--
-- Name: alarm_profile_overrides alarm_profile_overrides_profile_version_id_rule_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alarm_profile_overrides
    ADD CONSTRAINT alarm_profile_overrides_profile_version_id_rule_id_key UNIQUE (profile_version_id, rule_id);


--
-- Name: alarm_profile_versions alarm_profile_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alarm_profile_versions
    ADD CONSTRAINT alarm_profile_versions_pkey PRIMARY KEY (id);


--
-- Name: episode_escalations alert_escalations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episode_escalations
    ADD CONSTRAINT alert_escalations_pkey PRIMARY KEY (id);


--
-- Name: episode_transitions alert_transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episode_transitions
    ADD CONSTRAINT alert_transitions_pkey PRIMARY KEY (id);


--
-- Name: episodes alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: auth_sessions auth_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT auth_sessions_pkey PRIMARY KEY (token_hash);


--
-- Name: bathroom_summaries bathroom_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bathroom_summaries
    ADD CONSTRAINT bathroom_summaries_pkey PRIMARY KEY (id);


--
-- Name: bathroom_summaries bathroom_summaries_source_record_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bathroom_summaries
    ADD CONSTRAINT bathroom_summaries_source_record_id_key UNIQUE (source_record_id);


--
-- Name: beds beds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beds
    ADD CONSTRAINT beds_pkey PRIMARY KEY (id);


--
-- Name: care_notes care_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.care_notes
    ADD CONSTRAINT care_notes_pkey PRIMARY KEY (id);


--
-- Name: care_summaries care_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.care_summaries
    ADD CONSTRAINT care_summaries_pkey PRIMARY KEY (id);


--
-- Name: care_summaries care_summaries_source_record_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.care_summaries
    ADD CONSTRAINT care_summaries_source_record_id_key UNIQUE (source_record_id);


--
-- Name: clip_windows clip_windows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clip_windows
    ADD CONSTRAINT clip_windows_pkey PRIMARY KEY (window_id);


--
-- Name: current_bed_states current_bed_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_bed_states
    ADD CONSTRAINT current_bed_states_pkey PRIMARY KEY (bed_id);


--
-- Name: episode_notes episode_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episode_notes
    ADD CONSTRAINT episode_notes_pkey PRIMARY KEY (id);


--
-- Name: episode_timeline_events episode_timeline_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episode_timeline_events
    ADD CONSTRAINT episode_timeline_events_pkey PRIMARY KEY (id);


--
-- Name: evidence evidence_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence
    ADD CONSTRAINT evidence_pkey PRIMARY KEY (id);


--
-- Name: facilities facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT facilities_pkey PRIMARY KEY (id);


--
-- Name: facility_shifts facility_shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facility_shifts
    ADD CONSTRAINT facility_shifts_pkey PRIMARY KEY (id);


--
-- Name: history_episode_detections incident_detections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_episode_detections
    ADD CONSTRAINT incident_detections_pkey PRIMARY KEY (id);


--
-- Name: history_episode_detections incident_detections_source_record_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_episode_detections
    ADD CONSTRAINT incident_detections_source_record_id_key UNIQUE (source_record_id);


--
-- Name: history_episode_reviews incident_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_episode_reviews
    ADD CONSTRAINT incident_reviews_pkey PRIMARY KEY (id);


--
-- Name: mobility_summaries mobility_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobility_summaries
    ADD CONSTRAINT mobility_summaries_pkey PRIMARY KEY (id);


--
-- Name: mobility_summaries mobility_summaries_source_record_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobility_summaries
    ADD CONSTRAINT mobility_summaries_source_record_id_key UNIQUE (source_record_id);


--
-- Name: notification_deliveries notification_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_deliveries
    ADD CONSTRAINT notification_deliveries_pkey PRIMARY KEY (id);


--
-- Name: notification_delivery_events notification_delivery_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_delivery_events
    ADD CONSTRAINT notification_delivery_events_pkey PRIMARY KEY (id);


--
-- Name: notification_events notification_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_events
    ADD CONSTRAINT notification_events_pkey PRIMARY KEY (id);


--
-- Name: planogram_placements planogram_placements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planogram_placements
    ADD CONSTRAINT planogram_placements_pkey PRIMARY KEY (id);


--
-- Name: policy_recommendations policy_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policy_recommendations
    ADD CONSTRAINT policy_recommendations_pkey PRIMARY KEY (id);


--
-- Name: resident_bed_assignments resident_bed_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resident_bed_assignments
    ADD CONSTRAINT resident_bed_assignments_pkey PRIMARY KEY (id);


--
-- Name: resident_notes resident_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resident_notes
    ADD CONSTRAINT resident_notes_pkey PRIMARY KEY (id);


--
-- Name: resident_profiles resident_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resident_profiles
    ADD CONSTRAINT resident_profiles_pkey PRIMARY KEY (id);


--
-- Name: residents residents_external_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.residents
    ADD CONSTRAINT residents_external_id_key UNIQUE (external_id);


--
-- Name: residents residents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.residents
    ADD CONSTRAINT residents_pkey PRIMARY KEY (id);


--
-- Name: room_privacy_regions room_privacy_regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_privacy_regions
    ADD CONSTRAINT room_privacy_regions_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: round_tasks round_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_tasks
    ADD CONSTRAINT round_tasks_pkey PRIMARY KEY (id);


--
-- Name: rounds rounds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT rounds_pkey PRIMARY KEY (id);


--
-- Name: scene_events scene_events_event_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scene_events
    ADD CONSTRAINT scene_events_event_id_key UNIQUE (event_id);


--
-- Name: scene_events scene_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scene_events
    ADD CONSTRAINT scene_events_pkey PRIMARY KEY (id);


--
-- Name: sensor_events sensor_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_events
    ADD CONSTRAINT sensor_events_pkey PRIMARY KEY (id);


--
-- Name: sensor_events sensor_events_source_event_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensor_events
    ADD CONSTRAINT sensor_events_source_event_id_key UNIQUE (source_event_id);


--
-- Name: shift_notes shift_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shift_notes
    ADD CONSTRAINT shift_notes_pkey PRIMARY KEY (id);


--
-- Name: sleep_summaries sleep_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sleep_summaries
    ADD CONSTRAINT sleep_summaries_pkey PRIMARY KEY (id);


--
-- Name: sleep_summaries sleep_summaries_source_record_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sleep_summaries
    ADD CONSTRAINT sleep_summaries_source_record_id_key UNIQUE (source_record_id);


--
-- Name: staff_groups staff_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_groups
    ADD CONSTRAINT staff_groups_pkey PRIMARY KEY (id);


--
-- Name: stream_regions stream_regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_regions
    ADD CONSTRAINT stream_regions_pkey PRIMARY KEY (id);


--
-- Name: streams streams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.streams
    ADD CONSTRAINT streams_pkey PRIMARY KEY (id);


--
-- Name: timelines timelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timelines
    ADD CONSTRAINT timelines_pkey PRIMARY KEY (id);


--
-- Name: unit_shift_coverages unit_shift_coverages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unit_shift_coverages
    ADD CONSTRAINT unit_shift_coverages_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: wings wings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wings
    ADD CONSTRAINT wings_pkey PRIMARY KEY (id);


--
-- Name: audit_log_actor_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_actor_time_idx ON public.audit_log USING btree (actor_id, created_at DESC);


--
-- Name: audit_log_entity_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_entity_time_idx ON public.audit_log USING btree (entity_type, entity_id, created_at DESC);


--
-- Name: auth_sessions_user_expiry_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_sessions_user_expiry_idx ON public.auth_sessions USING btree (user_id, expires_at);


--
-- Name: beds_active_monitor_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX beds_active_monitor_idx ON public.beds USING btree (monitor_key) WHERE ((monitor_key IS NOT NULL) AND (retired_at IS NULL));


--
-- Name: beds_open_assignment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX beds_open_assignment_idx ON public.resident_bed_assignments USING btree (bed_id) WHERE (ends_at IS NULL);


--
-- Name: idx_alarm_profiles_one_current; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_alarm_profiles_one_current ON public.alarm_profile_versions USING btree (resident_id) WHERE (valid_to IS NULL);


--
-- Name: idx_bathroom_summaries_resident_day; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_bathroom_summaries_resident_day ON public.bathroom_summaries USING btree (resident_id, observed_on);


--
-- Name: idx_care_summaries_resident_day; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_care_summaries_resident_day ON public.care_summaries USING btree (resident_id, observed_on);


--
-- Name: idx_episode_escalations_episode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_episode_escalations_episode ON public.episode_escalations USING btree (episode_id);


--
-- Name: idx_episode_notes_episode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_episode_notes_episode ON public.episode_notes USING btree (episode_id);


--
-- Name: idx_episode_transitions_episode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_episode_transitions_episode ON public.episode_transitions USING btree (episode_id);


--
-- Name: idx_episodes_occurred; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_episodes_occurred ON public.episodes USING btree (occurred_at);


--
-- Name: idx_episodes_resident; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_episodes_resident ON public.episodes USING btree (resident_id);


--
-- Name: idx_episodes_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_episodes_status ON public.episodes USING btree (status);


--
-- Name: idx_ete_episode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ete_episode ON public.episode_timeline_events USING btree (episode_id, at);


--
-- Name: idx_ete_resident; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ete_resident ON public.episode_timeline_events USING btree (resident_id, at);


--
-- Name: idx_mobility_summaries_resident_day; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_mobility_summaries_resident_day ON public.mobility_summaries USING btree (resident_id, observed_on);


--
-- Name: idx_notification_deliveries_episode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_deliveries_episode ON public.notification_deliveries USING btree (episode_id);


--
-- Name: idx_pr_resident_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pr_resident_state ON public.policy_recommendations USING btree (resident_id, state);


--
-- Name: idx_resident_notes_resident; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_resident_notes_resident ON public.resident_notes USING btree (resident_id);


--
-- Name: idx_resident_notes_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_resident_notes_timestamp ON public.resident_notes USING btree ("timestamp");


--
-- Name: idx_rp_resident_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_rp_resident_version ON public.resident_profiles USING btree (resident_id, version);


--
-- Name: idx_sensor_events_unresolved; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sensor_events_unresolved ON public.sensor_events USING btree (monitor_key) WHERE (bed_id IS NULL);


--
-- Name: idx_shift_notes_facility; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shift_notes_facility ON public.shift_notes USING btree (facility_id, shift_date);


--
-- Name: idx_shift_notes_wing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shift_notes_wing ON public.shift_notes USING btree (wing_id, shift_date) WHERE (wing_id IS NOT NULL);


--
-- Name: idx_sleep_summaries_resident_day; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_sleep_summaries_resident_day ON public.sleep_summaries USING btree (resident_id, observed_on);


--
-- Name: residents_open_assignment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX residents_open_assignment_idx ON public.resident_bed_assignments USING btree (resident_id) WHERE (ends_at IS NULL);


--
-- Name: rooms_active_number_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX rooms_active_number_idx ON public.rooms USING btree (wing_id, number) WHERE (retired_at IS NULL);


--
-- Name: rounds_wing_in_progress_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX rounds_wing_in_progress_idx ON public.rounds USING btree (wing_id) WHERE (status = 'in_progress'::text);


--
-- Name: streams_active_room_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX streams_active_room_key_idx ON public.streams USING btree (room_id, stream_key) WHERE (active = true);


--
-- Name: alarm_profile_overrides alarm_profile_overrides_profile_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alarm_profile_overrides
    ADD CONSTRAINT alarm_profile_overrides_profile_version_id_fkey FOREIGN KEY (profile_version_id) REFERENCES public.alarm_profile_versions(id);


--
-- Name: episode_escalations alert_escalations_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episode_escalations
    ADD CONSTRAINT alert_escalations_alert_id_fkey FOREIGN KEY (episode_id) REFERENCES public.episodes(id);


--
-- Name: episode_transitions alert_transitions_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episode_transitions
    ADD CONSTRAINT alert_transitions_alert_id_fkey FOREIGN KEY (episode_id) REFERENCES public.episodes(id);


--
-- Name: auth_sessions auth_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_sessions
    ADD CONSTRAINT auth_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: beds beds_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beds
    ADD CONSTRAINT beds_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: notification_deliveries notification_deliveries_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_deliveries
    ADD CONSTRAINT notification_deliveries_alert_id_fkey FOREIGN KEY (episode_id) REFERENCES public.episodes(id);


--
-- Name: notification_delivery_events notification_delivery_events_delivery_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_delivery_events
    ADD CONSTRAINT notification_delivery_events_delivery_id_fkey FOREIGN KEY (delivery_id) REFERENCES public.notification_deliveries(id);


--
-- Name: planogram_placements planogram_placements_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planogram_placements
    ADD CONSTRAINT planogram_placements_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: planogram_placements planogram_placements_wing_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planogram_placements
    ADD CONSTRAINT planogram_placements_wing_id_fkey FOREIGN KEY (wing_id) REFERENCES public.wings(id);


--
-- Name: resident_bed_assignments resident_bed_assignments_resident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resident_bed_assignments
    ADD CONSTRAINT resident_bed_assignments_resident_id_fkey FOREIGN KEY (resident_id) REFERENCES public.residents(id);


--
-- Name: room_privacy_regions room_privacy_regions_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_privacy_regions
    ADD CONSTRAINT room_privacy_regions_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: rooms rooms_wing_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_wing_id_fkey FOREIGN KEY (wing_id) REFERENCES public.wings(id);


--
-- Name: round_tasks round_tasks_round_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_tasks
    ADD CONSTRAINT round_tasks_round_id_fkey FOREIGN KEY (round_id) REFERENCES public.rounds(id);


--
-- Name: stream_regions stream_regions_stream_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stream_regions
    ADD CONSTRAINT stream_regions_stream_id_fkey FOREIGN KEY (stream_id) REFERENCES public.streams(id);


--
-- Name: wings wings_facility_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wings
    ADD CONSTRAINT wings_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id);


--
-- PostgreSQL database dump complete
--

\unrestrict QFgIlmYIkF0EfaetfaiXwrj5h8nxn8cnCXCg7sfsKcC6czBY6EwvhpQNCsGR232

