Exactly—because Round 2 is only **11:00–11:30 AM**, they cannot test everything. Expect approximately 6–8 meaningful questions with cross-questioning.

## Most likely structure

```text
11:00–11:04  Introduction and current responsibilities
11:04–11:14  Roll On Dispatch experience and one feature
11:14–11:23  3–4 technical questions
11:23–11:27  Web Forms/Telerik, availability, motivation
11:27–11:30  Your questions
```

## Prepare these eight answers

1. **90-second introduction**
2. **60-second Roll On Dispatch explanation**
3. **One feature end to end:** attachment transaction
4. **Project architecture, layers, and domain**
5. **Strategy Pattern + Repository Pattern**
6. **DI and program to an interface**
7. **EF Core and SQL performance**
8. **Web Forms/Telerik experience-gap answer**

GraphQL is backup preparation because they asked it recently.

## Your primary feature story

Use the attachment workflow:

```text
Web/mobile client
  → authenticated upload API
  → controller validation
  → DriverLoadService
  → upload file to Azure Blob
  → save attachment metadata in SQL
  → update driver-load/shipment status
  → transaction for SQL changes
  → structured response and logging
```

Then proactively mention:

> The SQL transaction cannot automatically roll back Azure Blob Storage. A more resilient design uses compensating deletion or Pending and Completed states with reconciliation.

That statement demonstrates real engineering maturity and creates strong follow-up discussion.

## Likely five-question chain

They may spend most of the interview on this:

1. Explain the attachment feature.
2. Why did you need a transaction?
3. What happens if blob upload succeeds but SQL fails?
4. How did you test it?
5. How did you debug or monitor failures?

If you answer this chain confidently, you can control nearly half the interview.

## Web Forms/Telerik answer

> My production experience is primarily ASP.NET Core rather than Web Forms, and I have not used Telerik extensively in production. However, my transferable foundation is strong in C#, SQL Server, REST integration, business workflows, debugging, and layered applications. I understand Web Forms concepts such as page lifecycle, postbacks, ViewState, code-behind, server controls, and event handling. I also understand Telerik’s data-bound control model, particularly RadGrid and NeedDataSource. I’m confident I can become productive quickly without overstating my current experience.

## Revised preparation for tonight

You do not need another eight hours of studying.

- **90 minutes:** introduction, project, architecture, attachment story
- **60 minutes:** DI, patterns, repository, EF Core
- **60 minutes:** SQL Server
- **45 minutes:** Web Forms and Telerik
- **45 minutes:** two spoken mock interviews
- **30 minutes:** GraphQL and HR questions

Then stop and sleep.

## Answer-length rule

- Definition question: **30–45 seconds**
- Project question: **60–90 seconds**
- Scenario question: **up to two minutes**
- Then pause and let them cross-question

Do not turn every answer into a lecture. Start with the direct answer, give one ROD example, mention one trade-off, and stop.

## Questions to ask them

Keep two ready:

> What kind of work would be the first priority for this role—existing Web Forms maintenance, new development, or modernization?

> How is the second-round evaluation different from the first round, and what would success in the first three months look like?

For this round, depth on one real project story will matter more than broad memorization.