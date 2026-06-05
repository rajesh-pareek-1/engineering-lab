# Engineering Lab Interview Revision

This repo is now organized for fast interview revision instead of raw dumping.

## How To Use

For a 5 minute refresh:

1. Read [last-minute-interview.md](last-minute-interview.md).
2. Scan [notes/question-bank-prioritized.md](notes/question-bank-prioritized.md).
3. Speak the project pitch from [experience/roll-on-dispatch.md](experience/roll-on-dispatch.md).

For a 30 minute backend revision:

1. [notes/dotnet-webapi.md](notes/dotnet-webapi.md)
2. [notes/csharp-runtime-performance.md](notes/csharp-runtime-performance.md)
3. [notes/efcore-linq.md](notes/efcore-linq.md)
4. [notes/sql-revision.md](notes/sql-revision.md)
5. [experience/multitenancy-deep-dive.md](experience/multitenancy-deep-dive.md)

For coding rounds:

1. [coding/csharp-output-traps.md](coding/csharp-output-traps.md)
2. [coding/csharp-coding-drills.md](coding/csharp-coding-drills.md)
3. [coding/javascript-this-bind-closures.md](coding/javascript-this-bind-closures.md)

For structured practice:

1. [notes/7-day-revision-plan.md](notes/7-day-revision-plan.md)
2. [mock-interviews/backend-round.md](mock-interviews/backend-round.md)
3. [mock-interviews/resume-based-round.md](mock-interviews/resume-based-round.md)
4. [mock-interviews/dotnet-deep-dive.md](mock-interviews/dotnet-deep-dive.md)
5. [mock-interviews/sql-round.md](mock-interviews/sql-round.md)

For scratch coding:

1. [scripts/README.md](scripts/README.md)
2. [scripts/csharp/scratch.csx](scripts/csharp/scratch.csx)
3. [scripts/javascript/play.js](scripts/javascript/play.js)

## Folder Structure

- `notes/` - normalized .NET, C#, SQL, EF Core, LINQ, API, and question bank notes.
- `coding/` - coding drills and output-trap revision.
- `experience/` - project stories, resume answer bank, and multi-tenancy deep dive.
- `mock-interviews/` - interview rounds with weak answer vs strong answer guidance.
- `arena-search/` - referral and job-search templates.
- `scripts/` - scratch C# and JavaScript practice area.
- `resumes/` - resume PDFs only.
- `source-map.md` - what each old file was converted into.

## Revision Rule

Answer every topic in this format:

```text
Definition -> Key insight -> Project example -> Tradeoff
```

Example:

```text
Async/await enables non-blocking I/O.
It frees the request thread while DB/API calls are in progress.
In RollOnDispatch, async APIs prevent shipment and invoice requests from blocking.
The trap is using .Result or .Wait(), which can block threads and cause deadlocks.
```
