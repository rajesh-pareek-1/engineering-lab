📘** DOTNET / BACKEND INTERVIEW QUESTION BANK (REFINED)**

🔵** 1. ASP.NET Core & Web API Fundamentals**

**1. Which framework did you work on for REST APIs?**

👉 Tests:

- Your actual experience clarity
- Whether you understand **.NET Core vs older frameworks**

**2. What is the lifecycle of an HTTP request in .NET Core?**

👉 Tests:

- Deep understanding of **request pipeline**
- Middleware execution order
- Routing → Controller → Response flow

**3. What is the difference between IActionResult and ActionResult?**

👉 Tests:

- Flexibility of response types
- API design knowledge
- Strong typing vs abstraction

**4. What is model binding in .NET Core Web API?**

👉 Tests:

- How data flows from request → controller
- Query string, body, route binding

**5. How do you implement custom middleware in .NET Core?**

👉 Tests:

- Pipeline customization
- Delegates & request flow control

**6. What is the order of middleware execution?**

👉 Tests:

- Understanding of pipeline sequence
- Importance of ordering

🔵** 2. Security & Authentication**

**7. How would you implement global exception handling in API?**

👉 Tests:

- Production-level error handling
- Middleware usage
- Centralized logging

**8. How is JWT authentication implemented?**

👉 Tests:

- Token generation & validation
- Claims, expiry, authorization

**9. What is OAuth & OpenID Connect?**

👉 Tests:

- Authentication vs Authorization understanding
- Industry-standard auth flows

**10. How do you secure a Web API?**

👉 Tests:

- Practical security awareness
- JWT, HTTPS, validation, rate limiting

🔵** 3. Serialization & JSON Handling**

**11. What is Newtonsoft.Json and its benefits?**

👉 Tests:

- Legacy vs modern JSON handling
- Flexibility in serialization

**12. What is System.Text.Json?**

👉 Tests:

- Performance awareness
- Modern .NET improvements

**13. How do you handle circular references in JSON?**

👉 Tests:

- Real-world serialization problems
- Reference handling strategies

🔵** 4. API Design**

**14. How do you implement API versioning?**

👉 Tests:

- Backward compatibility
- Real-world API evolution

🔵** 5. Caching & Performance**

**15. What types of caching have you used?**

👉 Tests:

- Knowledge of caching strategies
- Performance optimization

**16. How do you handle frequently accessed data using Redis?**

👉 Tests:

- Distributed caching
- High-performance system design

**17. What is in-memory caching?**

👉 Tests:

- Local caching vs distributed caching
- Trade-offs

🔵** 6. Asynchronous Programming**

**18. What is async/await in APIs?**

👉 Tests:

- Non-blocking I/O understanding
- Thread usage & scalability

**19. Async vs Task.WhenAll vs Task.WaitAll**

👉 Tests:

- Parallel execution
- Thread blocking vs non-blocking

🔵** 7. Background Processing & Queues**

**20. What is a queue system?**

👉 Tests:

- Decoupling services
- Asynchronous processing

**21. What is a background worker?**

👉 Tests:

- Long-running tasks handling
- Offloading work from request thread

**22. How do you process messages from a queue?**

👉 Tests:

- Event-driven architecture
- Message consumption

**23. How do you handle high request load using queues?**

👉 Tests:

- Scalability
- System design thinking

🔵** 8. Database & SQL**

**24. Optimizing SQL queries**

👉 Tests:

- Indexing
- Query performance
- Execution plans

**25. GROUP BY vs HAVING**

👉 Tests:

- Query execution order
- Aggregation filtering

**26. Difference between Dense Rank and Rank**

👉 Tests:

- Window functions
- Ranking logic

**27. What is partition in SQL?**

👉 Tests:

- Window functions
- Data segmentation

**28. Stored Procedure vs Trigger**

👉 Tests:

- DB automation vs manual execution

**29. Can we call stored procedure inside function?**

👉 Tests:

- SQL constraints
- Execution rules

🔵** 9. C# Core Concepts**

**30. String vs StringBuilder**

👉 Tests:

- Memory & performance understanding

**31. Ref vs Out**

👉 Tests:

- Parameter passing behavior

**32. Override vs Overload**

👉 Tests:

- Compile-time vs runtime polymorphism

**33. Static vs Private**

👉 Tests:

- Access modifiers & usage

**34. Garbage Collection**

👉 Tests:

- Memory management

**35. IDisposable vs GC**

👉 Tests:

- Deterministic vs non-deterministic cleanup

🔵** 10. OOP & SOLID**

**36. What is OOP?**

👉 Tests:

- Basic OOP pillars

**37. Inheritance & Abstraction**

👉 Tests:

- Reusability & design

**38. Encapsulation vs Abstraction**

👉 Tests:

- Data hiding vs implementation hiding

**39. SOLID Principles**

👉 Tests:

- Clean architecture understanding

**40. Liskov Substitution Principle (with example)**

👉 Tests:

- Substitutability in inheritance

🔵** 11. Architecture & Design**

**41. Monolithic vs Microservices**

👉 Tests:

- Architecture trade-offs

**42. API Gateway**

👉 Tests:

- Microservice routing & security

**43. How do microservices communicate?**

👉 Tests:

- Inter-service communication (REST, messaging)

**44. How many databases in microservices?**

👉 Tests:

- Database per service pattern

🔵** 12. Caching, Concurrency & Performance**

**45. ConcurrentDictionary**

👉 Tests:

- Thread-safe collections

**46. Lock()**

👉 Tests:

- Thread synchronization

**47. Rate Limiting**

👉 Tests:

- API protection strategies

**48. Handling 100+ concurrent requests**

👉 Tests:

- Load handling & scalability

🔵** 13. LINQ & Collections**

**49. FirstOrDefault vs SingleOrDefault**

👉 Tests:

- Query behavior differences

**50. IEnumerable vs IQueryable**

👉 Tests:

- Client vs server execution

**51. Deferred Execution in LINQ**

👉 Tests:

- Execution timing

🔵** 14. Advanced SQL & Data**

**52. CTE (Common Table Expression)**

👉 Tests:

- Readable complex queries

**53. Temp Tables**

👉 Tests:

- Temporary data handling

**54. Indexing**

👉 Tests:

- Query optimization

🔵** 15. Misc Backend Concepts**

**55. Idempotency**

👉 Tests:

- API reliability

**56. Content-Type vs Accept Headers**

👉 Tests:

- Request/response content negotiation

**57. HttpClient implementation**

👉 Tests:

- External API communication

**58. NuGet Packages**

👉 Tests:

- Dependency management

🔵** 16. Code & Output Questions**

**59. Employee class output (your C# question)**

👉 Tests:

- Properties + encapsulation + access modifiers

**60. SQL Query: sum salary > 3000**

👉 Tests:

- GROUP BY + HAVING

**61. Longest subarray with sum k**

👉 Tests:

- Problem solving + prefix sum + hashing

**62. Second highest salary without ranking functions**

👉 Tests:

- Subqueries + SQL depth

🎯** HOW TO USE THIS LIST (IMPORTANT)**

👉 Don’t try to memorize all

👉 Instead:

**Step 1:**

Pick **10–15 strongest topics**

**Step 2:**

For each:

- Prepare **real explanation**
- Add **1 real example**
- Add **1 improvement / trade-off**

🚀** WHAT YOU JUST BUILT**

You now have:

✅ Structured question bank

✅ What interviewer is testing

✅ Preparation roadmap

🔥** NEXT (HIGH IMPACT)**

👉 Next step is:
