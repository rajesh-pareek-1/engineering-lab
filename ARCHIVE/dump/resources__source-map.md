# Source Map

Historical note: this file records the pre-Interview OS normalization map. Paths such as `notes/...`, `coding/...`, and `experience/...` are legacy destinations. Use `../archive/migration-notes.md` or `../RESTRUCTURE_REPORT.md` for the current structure.


This file records how the messy source files were normalized.

## Root

| Old source | Clean destination | Notes |
| --- | --- | --- |
| `README.md` | `notes/sql-revision.md` | The old README only had an incomplete dense-rank SQL snippet. Corrected and folded into SQL notes. |
| `dotnetITR.txt` | `notes/question-bank-prioritized.md`, `notes/dotnet-webapi.md`, `notes/csharp-runtime-performance.md` | Raw interview question list deduplicated and grouped. |
| `.vscode/settings.json` | Removed | Editor color settings, not interview knowledge. |
| `.DS_Store` files | Removed | macOS metadata. |
| `study-notes/.DS_Store` | Removed | Empty/no useful study content. |

## TimeToBleBaby

| Old source | Clean destination | Notes |
| --- | --- | --- |
| `1_dotnetFamily.md` | `notes/dotnet-webapi.md` | .NET history, MVC/API, Razor, middleware, filters. |
| `2_RODDescription.md` | `experience/roll-on-dispatch.md` | Project pitch, API flow, architecture, tradeoffs. |
| `2yearROIQuickSheet.md` | `notes/efcore-linq.md`, `notes/csharp-runtime-performance.md`, `notes/dotnet-webapi.md` | Strong 2-3 YOE one-liners merged by topic. |
| `3_shiveshRohitQuestionsAnswers.md` | `notes/question-bank-prioritized.md`, `notes/dotnet-webapi.md` | 62 arena questions normalized into grouped notes. |
| `4_2yearDifferentiatorscheatsheet.md` | `notes/csharp-runtime-performance.md`, `notes/question-bank-prioritized.md` | Runtime, GC, async, DI, caching, architecture differentiators. |
| `5_1_SQLFundmentals.md` | `notes/sql-revision.md` | SQL fundamentals and execution order. |
| `5_sqlCheatSheet.md` | `notes/sql-revision.md` | SQL interview problems and EF conversions. |
| `6_syntaxCodingBasics.md` | `coding/csharp-coding-drills.md` | Arrays, strings, collections, LINQ snippets. |
| `SOLID Principles.pdf` | `notes/csharp-oop-solid.md` | Non-resume PDF converted to Markdown concepts. |
| `net_revise.pdf` | `notes/csharp-oop-solid.md`, `notes/dotnet-webapi.md`, `notes/sql-revision.md` | Non-resume PDF converted and deduplicated. |
| `handsOn/cs_fundamentals/*.md` | `coding/csharp-output-traps.md` | C# memory model, copy traps, delegates, events, async, generics. |
| `handsOn/Nav_dotnetCore_23_March/questions.md` | `coding/csharp-output-traps.md`, `notes/sql-revision.md` | Deep-copy swap, polymorphism output, collections, constructor edge case. |
| `handsOn/Nav_dotnetCore_23_March/sql_invalid_product_ids.md` | `notes/sql-revision.md` | Group-level invalid-date SQL problem. |

## prep_i_popye

| Old source | Clean destination | Notes |
| --- | --- | --- |
| `backendPrep/top-dotnet_arena_question/playbook-questions-grouped.md` | `notes/question-bank-prioritized.md` | Tier A/B/C and broad .NET question bank. |
| `backendPrep/resumeBasedDiscussions/plan.md` | `notes/00-priority-roadmap.md` | Phase roadmap converted into revision plan. |
| `backendPrep/resumeBasedDiscussions/phase-1-multitenancy-dotnet/*.md` | `experience/multitenancy-deep-dive.md` | Multi-tenant architecture flow and risks. |
| `backendPrep/resumeBasedDiscussions/phase-1-multitenancy-dotnet/warpNotes/*.md` | `experience/multitenancy-deep-dive.md` | Deep-dive and principal engineer review consolidated. |

## docs_rs

| Old source | Clean destination | Notes |
| --- | --- | --- |
| `docs_rs/referral-docs/Referral Message.docx` | `arena-search/referral-template.md` | Word template converted to Markdown. |
| `docs_rs/**/*.pdf` | `resumes/` | Resume PDFs only. Kept as PDFs. |

## scripts

| Old source | Clean destination | Notes |
| --- | --- | --- |
| `scripts/js/fudamentals1.md` | `coding/javascript-this-bind-closures.md`, `scripts/javascript/play.js` | JS call/apply/bind notes normalized; a clean scratch area remains for practice. |
| `scripts/js/answers.md` | `coding/javascript-this-bind-closures.md` | Folded into JS weak-area notes. |
| `scripts/js/play.js` | `coding/javascript-this-bind-closures.md`, `scripts/javascript/play.js` | Small scratch code converted into notes; clean JS scratch file added. |
| `scripts/dotnet/out/Program.cs` | Removed | Empty file. |
| `scripts/dotnet/out/out.csproj` | `scripts/csharp/scratch.csx` | Empty project removed; clean C# script scratch file added. |
| `scripts/dotnet/out/bin`, `scripts/dotnet/out/obj` | Removed | Generated build artifacts. |

## Added During Final Prep Pass

| New file/folder | Purpose |
| --- | --- |
| `last-minute-interview.md` | Final 30-minute laser revision file. |
| `mock-interviews/` | Backend, .NET deep-dive, SQL, and resume-based interview packs. |
| `notes/7-day-revision-plan.md` | Practical 7-day interview sprint. |
| `scripts/` | C# and JavaScript scratch area for live practice. |
