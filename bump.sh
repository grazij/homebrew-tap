#!/usr/bin/env bash
#
# bump.sh — point a formula at a newer release and open the pull request.
#
# The formulae in this tap are the only copy; the projects they package no
# longer carry one. A bump is therefore a change to this repo, and it has to
# arrive as a PR: brew test-bot builds bottles on a pull request only, so a
# direct push to main ships a formula nobody has bottles for.
#
# The checksum is taken from the tarball GitHub actually serves, never
# computed locally from a tag — an archive's pax header carries the commit
# SHA, so a re-tagged release changes its checksum even when the tree does not.
#
# SPDX-License-Identifier: MIT

set -euo pipefail

PROG="${0##*/}"

# --- Defaults -----------------------------------------------------------

DRY_RUN=false
ASSUME_YES=false
VERBOSE=false
OPEN_PR=true
RETRIES=6
RETRY_DELAY=5

# --- Output -------------------------------------------------------------

if [[ -t 1 ]]
then
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RED=$'\033[31m'
  YELLOW=$'\033[33m'
  GREEN=$'\033[32m'
  RESET=$'\033[0m'
else
  BOLD='' DIM='' RED='' YELLOW='' GREEN='' RESET=''
fi

log() { printf '%s\n' "$*"; }
warn() { printf '%s%s: %s%s\n' "${YELLOW}" "${PROG}" "$*" "${RESET}" >&2; }

# die <exit-code> <message...>
die() {
  local code="$1"
  shift
  printf '%s%s: %s%s\n' "${RED}" "${PROG}" "$*" "${RESET}" >&2
  exit "${code}"
}

vlog() {
  [[ "${VERBOSE}" == true ]] || return 0
  printf '%s%s%s\n' "${DIM}" "$*" "${RESET}" >&2
}

need() {
  command -v "$1" >/dev/null 2>&1 || die 1 "required command not found: $1"
}

usage() {
  cat <<EOF
Usage: ${PROG} [OPTIONS] FORMULA VERSION

Rewrite Formula/FORMULA.rb to package VERSION, then open a pull request so
brew test-bot can build its bottles. The GitHub owner and repository are read
from the formula's existing url, so a formula packaging a third-party project
bumps the same way as one of ours.

VERSION is written as the tag spells it without the leading v — 1.5.5+grazij.6,
not v1.5.5+grazij.6. The tag must already be pushed: GitHub generates the
tarball on demand, so its checksum does not exist before then.

Casks are not handled; their url and version interpolate differently.

Positional arguments:
  FORMULA         Formula name, without the .rb — e.g. duti
  VERSION         Version the tag names, without the leading v

Options:
  -n, --dry-run   Print what would change; touch nothing.
  -y, --yes       Skip the confirmation prompt.
      --no-pr     Commit on a branch, but neither push nor open a PR.
  -v, --verbose   Print extra diagnostics to stderr.
  -h, --help      Show this help.

The branch is cut from whatever is checked out, so the working tree must be
clean and the current branch level with its counterpart on origin.

Exit status:
  0  success, or the formula was already at VERSION
  1  usage error, a missing dependency, or the tarball could not be fetched
  3  aborted at the confirmation prompt
  4  dirty working tree, detached HEAD, or a branch not level with origin

Examples:
  # See what would change
  ${PROG} --dry-run duti 1.5.5+grazij.6

  # Bump and open the PR, then apply the pr-pull label to land it
  ${PROG} duti 1.5.5+grazij.6
EOF
}

# --- Argument parsing ---------------------------------------------------

while [[ $# -gt 0 ]]
do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -n | --dry-run)
      DRY_RUN=true
      shift
      ;;
    -y | --yes)
      ASSUME_YES=true
      shift
      ;;
    --no-pr)
      OPEN_PR=false
      shift
      ;;
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      die 1 "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -ge 2 ]] || {
  usage >&2
  die 1 "FORMULA and VERSION are both required"
}

FORMULA="$1"
VERSION="${2#v}"
shift 2

FORMULA_FILE="Formula/${FORMULA}.rb"
[[ -f "${FORMULA_FILE}" ]] || die 1 "no such formula: ${FORMULA_FILE}"

# --- Temporary workspace ------------------------------------------------

WORKDIR=""
# shellcheck disable=SC2329  # invoked by the trap below
cleanup() {
  [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]] && rm -rf "${WORKDIR}"
  return 0
}
trap cleanup EXIT INT TERM
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/${PROG}.XXXXXX")"

# --- Helpers ------------------------------------------------------------

run() {
  if [[ "${DRY_RUN}" == true ]]
  then
    printf '%s[dry-run]%s %s\n' "${DIM}" "${RESET}" "$*"
    return 0
  fi
  vlog "+ $*"
  "$@"
}

# Ask before doing something irreversible, and stop here if the answer is no.
# It exits rather than returning a status because the only caller wanted
# exactly that, and a function invoked in an `||` condition silently disables
# set -e for everything it calls — which this tap's CI rejects (SC2310).
confirm_or_die() {
  [[ "${ASSUME_YES}" == true ]] && return 0
  [[ "${DRY_RUN}" == true ]] && return 0
  [[ -t 0 ]] || die 3 "$1 — no terminal to ask on; pass -y to proceed"

  local reply
  printf '%s%s%s [y/N] ' "${BOLD}" "$1" "${RESET}"
  read -r reply || die 3 "aborted"
  case "${reply}" in
    [yY] | [yY][eE][sS]) return 0 ;;
    *) die 3 "aborted" ;;
  esac
}

# The branch is cut from whatever is checked out, so anything already in the
# tree rides along in the bump commit, and a stale base produces a pull request
# test-bot builds against the wrong tree. Both are cheaper to refuse than to
# unpick once the PR is open. Like confirm_or_die, this exits rather than
# returning a status — see the note there (SC2310).
require_clean_current_checkout() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
    die 4 "not inside a git working tree"

  local dirty
  dirty="$(git status --porcelain)"
  [[ -z "${dirty}" ]] || die 4 "working tree is not clean; commit or stash first"

  local branch
  branch="$(git symbolic-ref --quiet --short HEAD)" ||
    die 4 "HEAD is detached; check out the branch you mean to bump from"

  git fetch --quiet origin "${branch}" ||
    die 4 "cannot reach origin to check ${branch} is current"

  local head_sha remote_sha
  head_sha="$(git rev-parse HEAD)"
  remote_sha="$(git rev-parse FETCH_HEAD)"
  [[ "${head_sha}" == "${remote_sha}" ]] ||
    die 4 "${branch} is not level with origin/${branch}; pull or push first"

  vlog "bumping from ${branch} at ${head_sha}"
}

# --- Main ---------------------------------------------------------------

need curl
need git
need shasum
[[ "${OPEN_PR}" == false ]] || need gh

# Checked even under --dry-run: a dry run that reports a clean bump while the
# real one would refuse is worse than no dry run.
require_clean_current_checkout

# The owner and repo come from the formula rather than a table here, so a
# formula pointing at somebody else's project needs no special case.
slug="$(sed -n 's|^[[:space:]]*url "https://github.com/\([^/]*/[^/]*\)/archive/.*|\1|p' "${FORMULA_FILE}")"
[[ -n "${slug}" ]] || die 1 "cannot read a github archive url from ${FORMULA_FILE}"
vlog "packaging ${slug}"

# A literal + in a URL path is ambiguous enough that GitHub's redirects
# mishandle it; %2B is not. The git tag itself keeps the literal +.
tag_path="v$(printf '%s' "${VERSION}" | sed 's/+/%2B/g')"
url="https://github.com/${slug}/archive/refs/tags/${tag_path}.tar.gz"

tarball="${WORKDIR}/archive.tar.gz"
attempt=1
while :
do
  if curl -fsSL -o "${tarball}" "${url}"
  then
    break
  fi
  [[ "${attempt}" -lt "${RETRIES}" ]] || die 1 "cannot fetch ${url}"
  warn "fetch failed, retrying in ${RETRY_DELAY}s (${attempt}/${RETRIES})"
  sleep "${RETRY_DELAY}"
  attempt=$((attempt + 1))
done

# An empty or missing-branch repo answers the archive URL with HTTP 200 and an
# HTML page, so curl -f succeeds and shasum hashes the HTML. Only unpacking
# tells the two apart; a non-empty check does not.
tar tzf "${tarball}" >/dev/null 2>&1 || die 1 "${url} is not a gzipped tar archive"

sha256="$(shasum -a 256 "${tarball}" | cut -d' ' -f1)"
[[ -n "${sha256}" ]] || die 1 "empty checksum for ${url}"
log "${FORMULA} ${VERSION}"
log "  url    ${url}"
log "  sha256 ${sha256}"

# Anchored to exactly two spaces so only the formula's own stanza is touched.
# A `resource` or `on_macos` block nests its `url` / `sha256` one level deeper,
# and an indentation-blind match would rewrite those to this tarball's values —
# silently, since the greps below only confirm the new values landed.
# `brew style` enforces the two-space body indent, so the anchor cannot drift.
#
# `version` is only rewritten where the formula already declares one. It is
# there to correct Version.detect on a +grazij.N tag; adding one to a formula
# that parses its version fine would be noise.
new="${WORKDIR}/formula.rb"
sed -e "s|^  url \".*\"|  url \"${url}\"|" \
  -e "s|^  version \".*\"|  version \"${VERSION}\"|" \
  -e "s|^  sha256 \".*\"|  sha256 \"${sha256}\"|" \
  "${FORMULA_FILE}" >"${new}"

grep -q "^  url \"${url}\"" "${new}" || die 1 "url line not rewritten in ${FORMULA_FILE}"
grep -q "^  sha256 \"${sha256}\"" "${new}" || die 1 "sha256 line not rewritten in ${FORMULA_FILE}"
if grep -q '^  version "' "${FORMULA_FILE}"
then
  grep -q "^  version \"${VERSION}\"" "${new}" || die 1 "version line not rewritten in ${FORMULA_FILE}"
fi

# Nothing but those three lines may differ. A formula that indents its stanza
# differently, or that carries a second url/sha256 at the same depth, lands here
# rather than in a pull request.
changed="$(diff "${FORMULA_FILE}" "${new}" | grep -c '^[<>]' || true)"
[[ "${changed}" -le 6 ]] || die 1 "unexpected rewrite in ${FORMULA_FILE}: ${changed} changed lines"

if cmp -s "${new}" "${FORMULA_FILE}"
then
  log "${GREEN}${FORMULA_FILE} already at ${VERSION}${RESET}"
  exit 0
fi

diff -u "${FORMULA_FILE}" "${new}" || true

branch="bump-${FORMULA}-${VERSION}"
confirm_or_die "Commit ${FORMULA_FILE} on ${branch} and open a PR?"

if [[ "${DRY_RUN}" == false ]]
then
  cat "${new}" >"${FORMULA_FILE}"
fi

run git checkout -b "${branch}"
run git add "${FORMULA_FILE}"
run git commit -m "${FORMULA} ${VERSION}"

if [[ "${OPEN_PR}" == false ]]
then
  log "${GREEN}Committed on ${branch}${RESET}; not pushed (--no-pr)"
  exit 0
fi

run git push -u origin "${branch}"
run gh pr create \
  --title "${FORMULA} ${VERSION}" \
  --body "sha256 taken from the tarball GitHub serves for ${tag_path}.

Apply the \`pr-pull\` label once test-bot is green — that is what pulls the
bottles onto main. Merging with the button instead lands the formula with no
bottle block."

if [[ "${DRY_RUN}" == false ]]
then
  log "${GREEN}PR opened${RESET}; apply the pr-pull label once test-bot is green"
fi
exit 0
