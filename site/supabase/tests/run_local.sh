#!/usr/bin/env bash
# Lokale test: maakt een verse database, past de migraties toe en draait de toegangstest.
# Vereist een lokale Postgres (PGHOST/PGPORT/PGUSER ingesteld).
set -e
cd "$(dirname "$0")/.."
dropdb --if-exists vgtest >/dev/null 2>&1 || true
createdb vgtest
psql -v ON_ERROR_STOP=1 -q -d vgtest -c "create extension if not exists pgcrypto" -f tests/00_supabase_mock.sql -f migrations/0001_schema.sql -f migrations/0002_toegang.sql -f migrations/0003_kader.sql -f migrations/0005_adviezen.sql -f migrations/0006_achtergrond.sql 2>&1 | grep -v NOTICE || true
psql -v ON_ERROR_STOP=1 -q -d vgtest -f tests/01_toegang_test.sql 2>&1 | grep -v -E "^ check|^-+$|^\s*$|^\(1 row\)|^ als|^ lever_opdracht_in|^ vraag_wijziging|^ beheer_profiel|^\s+$"
