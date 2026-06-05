# Restructure Report

Generated: 2026-06-05 11:30:51

## Summary

The repository was reorganized into an Interview OS with a small active revision surface, separate deep-dive material, mock arenas, project explanations, coding drills, resources, and archive. No files were permanently deleted.

## Final Structure

```text
/revision
/mock-arenas
/projects-explained
/engineering-lab
/coding-drills
/resources
/archive
```

## Classification

### Revision

- `revision/backend-webapi.md`
- `revision/csharp-oop-solid.md`
- `revision/csharp-runtime.md`
- `revision/ef-core-linq.md`
- `revision/last-30-minutes.md`
- `revision/last-minute-revision-path.md`
- `revision/project-defense.md`
- `revision/question-bank.md`
- `revision/react-native.md`
- `revision/sql.md`

### Deep-Dive

- `engineering-lab/csharp-oop-solid-deep-dive.md`
- `engineering-lab/csharp-runtime-performance-deep-dive.md`
- `engineering-lab/dotnet-webapi-deep-dive.md`
- `engineering-lab/ef-core-linq-deep-dive.md`
- `engineering-lab/react-native-internals-cheatsheet.md`
- `engineering-lab/react-navigation-screen-lifecycle.md`
- `engineering-lab/react-native-api-auth-offline-release.md`
- `engineering-lab/sql-interview-source.md`
- `engineering-lab/sql-leetcode-patterns.md`

### Mock Interview

- `mock-arenas/backend-round.md`
- `mock-arenas/dotnet-deep-dive.md`
- `mock-arenas/resume-based-round.md`
- `mock-arenas/sql-round.md`

### Project Explanation

- `projects-explained/multitenancy-deep-dive.md`
- `projects-explained/resume-answer-bank.md`
- `projects-explained/roll-on-dispatch.md`

### Coding Drills

- `coding-drills/csharp-coding-drills.md`
- `coding-drills/csharp-output-traps.md`
- `coding-drills/javascript-this-bind-closures.md`
- `coding-drills/scripts/README.md`
- `coding-drills/scripts/csharp/README.md`
- `coding-drills/scripts/javascript/README.md`

### Resources

- `resources/referral-template.md`
- `resources/resumes/README.md`
- `resources/source-map.md`

### Archive

- `archive/legacy/7-day-revision-plan.md`
- `archive/legacy/arena-search-readme.md`
- `archive/legacy/mock-readme.md`
- `archive/legacy/priority-roadmap.md`
- `archive/legacy/react-native-extra-blocks-original.md`
- `archive/legacy/react-native-readme.md`
- `archive/legacy/root-readme.md`

## What Was Moved

| From | To | Reason |
| --- | --- | --- |
| `README.md` | `archive/legacy/root-readme.md` | Preserved legacy root README before creating Interview OS home |
| `notes/dotnet-webapi.md` | `engineering-lab/dotnet-webapi-deep-dive.md` | Deep-dive source separated from quick revision |
| `notes/csharp-runtime-performance.md` | `engineering-lab/csharp-runtime-performance-deep-dive.md` | Deep-dive source separated from quick revision |
| `notes/csharp-oop-solid.md` | `engineering-lab/csharp-oop-solid-deep-dive.md` | Deep-dive source separated from quick revision |
| `notes/efcore-linq.md` | `engineering-lab/ef-core-linq-deep-dive.md` | Deep-dive source separated from quick revision |
| `notes/sql-revision.md` | `engineering-lab/sql-interview-source.md` | SQL source preserved after canonical SQL merge |
| `notes/leetcodeSql50.md` | `engineering-lab/sql-leetcode-patterns.md` | LeetCode SQL overlap preserved as deep practice source |
| `notes/question-bank-prioritized.md` | `revision/question-bank.md` | Deduplicated question bank is active revision |
| `notes/00-priority-roadmap.md` | `archive/legacy/priority-roadmap.md` | Replaced by new last-minute revision path |
| `notes/7-day-revision-plan.md` | `archive/legacy/7-day-revision-plan.md` | Replaced by new last-minute revision path |
| `arena-search/last-minute-interview.md` | `revision/last-30-minutes.md` | Fast interview-day recall file |
| `arena-search/referral-template.md` | `resources/referral-template.md` | Career resource |
| `arena-search/README.md` | `archive/legacy/arena-search-readme.md` | Legacy folder README replaced by resources navigation |
| `arena-search/resumes` | `resources/resumes` | Resume assets preserved under resources |
| `mock/backend-round.md` | `mock-arenas/backend-round.md` | Mock interview pack |
| `mock/dotnet-deep-dive.md` | `mock-arenas/dotnet-deep-dive.md` | Mock interview pack |
| `mock/resume-based-round.md` | `mock-arenas/resume-based-round.md` | Mock interview pack |
| `mock/sql-round.md` | `mock-arenas/sql-round.md` | Mock interview pack |
| `mock/README.md` | `archive/legacy/mock-readme.md` | Legacy mock README replaced by mock-arenas README |
| `experience/roll-on-dispatch.md` | `projects-explained/roll-on-dispatch.md` | Project material preserved |
| `experience/multitenancy-deep-dive.md` | `projects-explained/multitenancy-deep-dive.md` | Project material preserved |
| `experience/resume-answer-bank.md` | `projects-explained/resume-answer-bank.md` | Resume material preserved |
| `coding/csharp-coding-drills.md` | `coding-drills/csharp-coding-drills.md` | Coding drill |
| `coding/csharp-output-traps.md` | `coding-drills/csharp-output-traps.md` | Coding/output drill |
| `coding/javascript-this-bind-closures.md` | `coding-drills/javascript-this-bind-closures.md` | JavaScript callback drill |
| `scripts` | `coding-drills/scripts` | Scratch practice files moved under coding drills |
| `engineering-lab-react-native/react-native/cheatsheets/react-native-internals-cheatsheet.md` | `engineering-lab/react-native-internals-cheatsheet.md` | React Native deep-dive source |
| `engineering-lab-react-native/react-native/blocks/block-09-react-navigation-screen-lifecycle.md` | `engineering-lab/react-navigation-screen-lifecycle.md` | Canonical React Navigation lifecycle source |
| `engineering-lab-react-native/react-native/blocks/extrablocks.md` | `archive/legacy/react-native-extra-blocks-original.md` | Duplicate RN lifecycle archived before active merge |
| `engineering-lab-react-native/react-native/README.md` | `archive/legacy/react-native-readme.md` | Legacy React Native README replaced by engineering-lab navigation |
| `source-map.md` | `resources/source-map.md` | Repository origin/source resource |
| `REPO_INVENTORY.txt` | `archive/repo-snapshots/repo-inventory.txt` | Existing repo snapshot archived |
| `REPO_TREE.txt` | `archive/repo-snapshots/repo-tree.txt` | Existing repo snapshot archived |

## What Was Merged

- `revision/sql.md` merges the active SQL recall from `notes/sql-revision.md` and `notes/leetcodeSql50.md` while preserving full source notes in `engineering-lab/`.
- `revision/react-native.md` consolidates RN internals, navigation lifecycle, FlatList performance, auth/offline, and release interview points.
- `engineering-lab/react-native-api-auth-offline-release.md` keeps Block 10/11 content from the old extra blocks while removing duplicate Block 9 navigation content.
- `revision/backend-webapi.md` consolidates repeated API, queues, caching, auth, idempotency, and high-load answers.
- `revision/project-defense.md` condenses repeated resume/project answer scripts while preserving full project docs under `projects-explained/`.

## Duplicates Found

| Overlap | Files | Action |
| --- | --- | --- |
| SQL basics and LeetCode SQL | notes/sql-revision.md, notes/leetcodeSql50.md, mock/sql-round.md | Merged fast recall into revision/sql.md. Preserved originals as engineering-lab/sql-interview-source.md and engineering-lab/sql-leetcode-patterns.md. SQL mock remains practice-only. |
| React Native navigation lifecycle | block-09-react-navigation-screen-lifecycle.md and extrablocks.md Block 9 | Kept engineering-lab/react-navigation-screen-lifecycle.md as canonical. Archived original extrablocks and created engineering-lab/react-native-api-auth-offline-release.md without repeating navigation. |
| .NET/C# fundamentals | csharp-runtime-performance.md, csharp-oop-solid.md, question-bank-prioritized.md, mock/dotnet-deep-dive.md | Created canonical quick summaries under revision. Preserved deep notes under engineering-lab and mocks under mock-arenas. |
| EF Core performance concepts | efcore-linq.md, sql-revision.md EF example, roll-on-dispatch.md performance sections | Created revision/ef-core-linq.md and revision/sql.md as active recall. Project material remains under projects-explained for experience proof. |
| Queues/background jobs/idempotency | dotnet-webapi.md, roll-on-dispatch.md, resume-answer-bank.md, mock/backend-round.md | Created revision/backend-webapi.md as canonical technical recall and revision/project-defense.md as project-context recall. |
| Closures/callback traps | javascript-this-bind-closures.md and React Native stale closure sections | Kept JavaScript examples as drills and React Native closure guidance in revision/react-native.md. |

## Files Archived

| From | To | Reason |
| --- | --- | --- |
| `README.md` | `archive/legacy/root-readme.md` | Preserved legacy root README before creating Interview OS home |
| `notes/00-priority-roadmap.md` | `archive/legacy/priority-roadmap.md` | Replaced by new last-minute revision path |
| `notes/7-day-revision-plan.md` | `archive/legacy/7-day-revision-plan.md` | Replaced by new last-minute revision path |
| `arena-search/README.md` | `archive/legacy/arena-search-readme.md` | Legacy folder README replaced by resources navigation |
| `mock/README.md` | `archive/legacy/mock-readme.md` | Legacy mock README replaced by mock-arenas README |
| `engineering-lab-react-native/react-native/blocks/extrablocks.md` | `archive/legacy/react-native-extra-blocks-original.md` | Duplicate RN lifecycle archived before active merge |
| `engineering-lab-react-native/react-native/README.md` | `archive/legacy/react-native-readme.md` | Legacy React Native README replaced by engineering-lab navigation |
| `REPO_INVENTORY.txt` | `archive/repo-snapshots/repo-inventory.txt` | Existing repo snapshot archived |
| `REPO_TREE.txt` | `archive/repo-snapshots/repo-tree.txt` | Existing repo snapshot archived |

## Suggested Future Improvements

- Add a short confidence score to each revision file after mock practice.
- Add sample STAR stories for every resume bullet that appears in current PDFs.
- Add one SQL practice file with blank prompts before answers.
- Add a React Native mini mock arena if mobile-focused interviews become frequent.
- Keep deep-dive files source-like; only promote distilled points into revision.

## Migration Notes

See `archive/migration-notes.md` for the complete source-to-destination move log.
