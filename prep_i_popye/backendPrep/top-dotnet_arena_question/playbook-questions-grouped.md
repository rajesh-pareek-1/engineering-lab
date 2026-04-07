**Part 1: The Three-Tier Classification**

#### **Tier A: Core Backend Engineer (Deep Mastery)**

_Focus: Memory management, resource lifecycles, concurrency, and data integrity._
**Questions:** 5, 30, 40, 41, 47, 56, 57, 62, 63, 64, 72, 74, 76, 77, 78, 79, 80, 81, 82, 83, 85, 92, 93, 94, 99, 102, 103, 104, 105, 106, 107, 116, 117, 120, 121, 133, 138, 139, 142, 143, 144, 148, 149, 152, 153, 154, 157, 158, 161, 162, 163, 168, 169, 175, 178, 185, 186, 189, 190, 191, 199, 200, 201, 231, 232, 234–240 (SOLID), 241–250 (Design Patterns).

#### **Tier B: Supporting Knowledge (Confident & Concise)**

_Focus: Framework features, web standards, and common library usage._
**Questions:** 2, 4, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 32, 33, 35, 37, 38, 39, 42, 43, 44, 45, 46, 49, 50, 51, 52, 53, 54, 55, 58, 59, 60, 69, 70, 71, 73, 75, 84, 87, 88, 89, 90, 91, 95, 97, 98, 100, 122, 123, 124, 125, 127, 128, 129, 130, 131, 132, 134, 135, 136, 141, 145, 146, 147, 150, 151, 155, 156, 159, 160, 171, 172, 173, 174, 176, 177, 180, 181, 182, 183, 184, 187, 188, 192, 193, 194, 197, 198, 202, 203, 204, 205, 206, 233.

#### **Tier C: Basic / Entry Level (Definitions)**

_Focus: Syntax basics and introductory OOP concepts._
**Questions:** 1, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 31, 34, 36, 61, 65, 66, 67, 68, 86, 96, 101, 137, 140, 164, 165, 166, 167, 170, 179, 182, 183, 184, 185, 186, 187, 188.

---

### **Part 2: The Strong 2-Year Differentiators (40 Questions)**

These questions distinguish a **Systems Engineer** from a "feature coder" by testing their understanding of **resource taxes and trade-offs** .

**Reflection (5):** Tests understanding of runtime metadata and performance overhead.

**IEnumerable vs. IEnumerator (47):** Shows if the dev understands state management during iteration.

**Throw vs. Throw ex (56/25):** A classic differentiator; using `throw ex` destroys the diagnostic trail.

**Generics Performance (57):** Differentiates those who know about boxing taxes.

**IEnumerable vs. IQueryable (64/133):** Critical for preventing the **N+1 problem** by moving filtering to the DB.

**Private Constructors (72):** Tests knowledge of the **Singleton Pattern** and inheritance prevention.

**Destructors (74):** Differentiates between managed and unmanaged cleanup.

**Boxing/Unboxing Performance (77):** Tests "Heap-allocation tax" awareness.

**GC Generations (80):** Shows if the dev understands how to minimize "Stop-the-World" pauses.

**Dispose vs. Finalize (81):** Essential for preventing **production socket/connection exhaustion** .

**Circular Reference (85):** Tests knowledge of memory leaks in complex object graphs.

**ConfigureServices vs. Configure (92/93):** Differentiates between **DI registration** and **Middleware pipeline** setup.

**Request Processing Pipeline (94):** Shows a holistic view of how a request survives the server.

**Custom Middleware (104):** Testing the ability to handle **cross-cutting concerns** like auth or logging.

**Request Delegate (106):** Tests low-level understanding of the ASP.NET pipeline.

**DI Lifetimes (AddSingleton, etc.) (120/121):** Critical to prevent **Captive Dependencies** that crash production apps.

**Connected vs. Disconnected Architecture (172):** Tests data-at-rest vs. data-in-flight strategy.

**ORM Approcahes (180):** Tests the ROI of Code-First vs. DB-First in a CI/CD environment.

**Web API vs. MVC Controller (189):** Tests understanding of content negotiation and statelessness.

**Basic vs. API Key vs. JWT Auth (191/195):** Tests the ability to choose the right security layer for N tenants.

**Content Negotiation (201):** Differentiates those who understand API flexibility.

**In-Memory vs. Distributed Caching (231):** Tests scalability awareness for **Web Farms** .

**Global Exception Handling (232):** Tests "Production Paranoia" and consistent error responses.

**SOLID: Single Responsibility (235):** Tests ability to keep logic pure and testable.

**SOLID: Open-Closed (236):** Testing if they use **Polymorphic Strategies** over deep `if-else` blocks.

**SOLID: Liskov Substitution (237):** The primary reason "clean" architectures fail in edge cases.

**SOLID: Dependency Inversion (239):** Tests understanding of **Domain Purity** vs. Infrastructure.

**Singleton Thread Safety (247):** Tests awareness of race conditions in high-concurrency.

**Factory vs. Abstract Factory (248/250):** Tests ability to manage complex object families in SaaS.

**Process vs. Thread (141):** Testing OS-level resource understanding.

**Task vs. Thread (143):** Testing knowledge of the **Thread Pool** and async efficiency.

**Lock Statement (144):** Essential for thread-safe state mutations.

**ACID Properties (144/37):** Testing the foundation of reliable transaction management.

**Stored Procedure vs. Function (138/35):** Testing data logic location strategy.

**Nth Highest Salary (143/37):** Testing complex SQL set-based logic over procedural row-thinking.

**View vs. Subquery (124/126):** Testing logical abstraction vs. query performance.

**Primary Key vs. Unique Key (122):** Testing knowledge of **Clustered vs. Non-clustered index** physical storage.

**CORS Restrictions (155/230):** Testing web security boundary knowledge.

**OData/Attribute Routing (181/154):** Testing modern API discoverability and contract management.

**Wait vs. Await (139):** (Implicit in Task questions) Tests understanding of **context switching** vs. thread blocking.

---

### **Part 3: Weak Fundamental Exposure (20 Questions)**

Answering these poorly signals a **"Black Box" mistake** —treating tools as magic without understanding the underlying reality.

1. **Difference between C# and .NET (1):** Failure shows total lack of environmental awareness.
2. **Object vs. Class (15):** Basic conceptual failure of OOP.
3. **Property vs. Function (19):** Shows lack of understanding of **invariant protection** .
4. **String vs. StringBuilder (32):** Poor answer shows ignorance of **heap fragmentation** and memory pressure.
5. **Throw vs. Throw ex (40):** A "red flag" answer indicating they destroy production stack traces.
6. **IEnumerable vs. IEnumerator (47):** Shows inability to explain the basic mechanics of how C# works.
7. **Pass by Value vs. Reference (49):** Fundamental logic error that leads to unintended data mutations.
8. **Constant vs. Readonly (58):** Shows ignorance of **runtime vs. compile-time** evaluation.
9. **Var vs. Dynamic (60):** Poor answer suggests they don't understand type safety or the DLR.
10. **What is a Constructor (65):** Failure here indicates no understanding of object lifecycle.
11. **Boxing/Unboxing (76):** Not knowing this implies they are creating **GC pressure** in every loop.
12. **Finally vs. Finalize (78/82):** Confusing these indicates they don't understand deterministic cleanup.
13. **Managed vs. Unmanaged (8):** If they can't define this, they don't understand the **CLR contract** .
14. **Authentication vs. Authorization (90):** Mixing these up is a critical security fundamental failure.
15. **Connected vs. Disconnected Architecture (172):** Essential for anyone claiming to work with databases.
16. **What is an ORM (127):** Failure shows lack of architectural layering knowledge.
17. **What is Middleware (104):** If they only know Controllers, they cannot build scalable, cross-cutting systems.
18. **Value Type vs. Reference Type (84/17):** Mixing up **Stack vs. Heap** indicates they cannot debug memory issues.
19. **DRY Principle (162/240):** Failing to articulate this indicates they write unmaintainable, redundant code.
20. **Is it always necessary to create objects? (66):** Testing knowledge of **Static members** and memory efficiency.

---

### **Why These Selections?**

- **Tier A** is selected because these concepts (like **IDisposable** and **DI Lifetimes** ) directly prevent system crashes like "SQL Connection Pool Exhaustion" found in the Audit.
- **The Differentiators** focus on **mathematical cost** (e.g., Boxing, N+1, Indexing) which represents the 30% performance boost target for senior roles.
- **Weak Fundamental** selections target the **"Black Box" mistake** . If a dev doesn't know why `throw ex` is bad, they are a production liability, regardless of how many features they can code.

Based on the uploaded documents, here are the interview questions extracted and categorized by technical domain. Duplicate questions were removed only if character-for-character identical, and original wording has been preserved.

### **1. CLR & Runtime Internals**

1. What is C#? What Is the difference between C# and .NET?
2. What are Namespaces?
3. What are the important components of .NET framework?
4. What is GAC?
5. What is Reflection?
6. WHAT IS JIT?
7. WHAT IS MSIL?
8. WHAT IS MEANT BY MANAGED AND UNMANAGED CODE?
9. WHAT IS DIFFERENCE BETWEEN NAMESPACE AND ASSEMBLY?
10. WHAT IS MANIFEST?
11. HOW MANAGED CODE IS EXECUTED?

### **2. C# Language Deep Dive**

12. What is OOPS? What are the main concepts of OOPS?
13. What are the advantages of OOPS?
14. What are the limitations of OOPS?
15. What are Classes and Objects?
16. What are the types of classes in C#?
17. Is it possible to prevent object creation of a class in C#?
18. What is Property?
19. What is the difference between Property and Function?
20. What is Inheritance? When to use Inheritance?
21. What are the different types of Inheritance?
22. Does C# support Multiple Inheritance?
23. How to prevent a class from being Inherited?
24. Are private class members inherited to the derived class?
25. What is Abstraction? How to implement abstraction?
26. Why to create Interfaces in real applications?
27. Can we define body of Interfaces methods? When to define methods in Interfaces?
28. What are Access Specifiers?
29. What is internal access modifier? Show example.
30. What is the default access modifier in a class?
31. What are the basic string operations in C#?
32. What is the difference between “String” and “StringBuilder”?
33. When to use String and when StringBuilder in real applications?
34. What is String Interpolation in C#?
35. What are the Loop types in C#? When to use what in real applications?
36. What is the difference between “continue” and “break” statement?
37. What are the alternative ways of writing if-else conditions? When to use what?
38. How to implement Exception Handling in C#?
39. Can we execute multiple Catch blocks?
40. What is the difference between “throw ex” and “throw”? Which one to use in real applications?
41. Explain Generics in C#? When and why to use?
42. What are Collections in C# and what are their types?
43. What is the difference between Array and ArrayList (atleast 2)?
44. What is the difference between Arraylist and Hashtable?
45. What is the difference between List and Dictionary Collections?
46. What is IEnumerable in C#?
47. What is the difference between IEnumerable and IEnumerator in C#?
48. What is a Method in C#?
49. What is the difference between Pass by Value and Pass by Reference Parameters?
50. How to return more than one value from a method in C#?
51. What is the difference between “out” and “ref” parameters?
52. What is “params” keyword? When to use params keyword in real applications?
53. What are optional parameters in a method?
54. What are named parameters in a method?
55. What are Extension Methods in C#? When to use extension methods?
56. What is ‘this’ keyword in C#? When to use it in real applications?
57. What is the difference between “is” and “as” operators?
58. What is the difference between “Readonly” and “Constant” variables?
59. What is “Static" class? When to use static class in real application?
60. What is the difference between “var” and “dynamic” in C#?
61. What is Enum keyword used for?
62. Is it possible to inherit Enum in C#?
63. What is the use of Yield keyword in C#?
64. WHAT IS THE DIFFERENCE BETWEEN A CLASS AND A STRUCTURE?
65. WHICH OOPS CONCEPT EXPOSES ONLY THE NECESSARY INFORMATION TO THE CALLING FUNCTIONS?
66. IS IT ALWAYS NECESSARY TO CREATE OBJECTS FROM CLASS?
67. WHAT IS EARLY AND LATE BINDING?
68. WHICH OOPS CONCEPT IS USED AS A REUSE MECHANISM?
69. WHAT YOU MEAN BY INNER EXCEPTION?
70. LIST OUT SOME OF THE EXCEPTIONS?
71. CAN WE OVERRIDE PRIVATE VIRTUAL METHOD?
72. WHAT IS “EXTERN” KEYWORD?
73. WHAT IS “SIZEOF” OPERATOR?
74. WHAT IS COVARIANCE IN C#?
75. WHAT IS THE DIFFERENCE BETWEEN SYSTEM EXCEPTIONS AND APPLICATION EXCEPTIONS?

### **3. Memory Management & GC**

76. What is Boxing and Unboxing? Where to use Boxing and Unboxing in real applications?
77. Is Boxing and Unboxing good for performance?
78. What is the difference between Finally and Finalize?
79. What is Garbage Collection(GC)?
80. What are Generations in garbage collection?
81. What is the difference between “Dispose” and “Finalize”?
82. What is the difference between “Finalize” and “Finally” methods?
83. Can we force Garbage Collector to run?
84. WHAT ARE VALUE TYPE AND REFERENCE TYPES?
85. EXPLAIN CIRCULAR REFERENCE?
86. EXPLAIN OBJECT POOL?

### **4. ASP.NET Core Pipeline**

87. What is MVC? Explain MVC Life cycle.
88. What are the advantages of MVC over Web Forms?
89. What are the different return types of a controller Action method?
90. What is Authentication and Authorization in ASP.NET MVC?
91. What is the role of Program.cs file in ASP.NET Core?
92. What is the role of ConfigureServices method?
93. What is the role of Configure method?
94. Describe the complete Request Processing Pipeline for ASP.NET Core MVC?
95. What is the difference between .NET Core and .NET 5?
96. What are the events in Page Life Cycle?
97. Explain default project structure in ASP.NET Core application?
98. How ASP.NET Core serve static files?
99. How to handle errors in ASP.NET Core?
100.  WHAT ARE THE 2 POPULAR ASP.NET MVC VIEW ENGINES?
101.  WHAT SYMBOL WOULD YOU USE TO DENOTE, THE START OF A CODE BLOCK IN RAZOR VIEWS?
102.  HOW TO ACCESS HTTPCONTEXT IN ASP.NET CORE?

### **5. Middleware & Filters**

103. What are Filters and their types in MVC?
104. What is Middleware in ASP.NET Core? What is custom middleware?
105. How ASP.NET Core Middleware is different from HttpModule?
106. What is Request Delegate in .NET Core?
107. What is Run(), Use() and Map() method?
108. IF I HAVE MULTIPLE FILTERS IMPLEMENTED, WHAT IS THE ORDER IN WHICH THESE FILTERS GET EXECUTED?
109. WHICH FILTER EXECUTES FIRST IN AN ASP.NET MVC APPLICATION?
110. WHAT ARE THE LEVELS AT WHICH FILTERS CAN BE APPLIED IN AN ASP.NET MVC APPLICATION?
111. IS IT POSSIBLE TO CREATE A CUSTOM FILTER?
112. WHAT FILTERS ARE EXECUTED IN THE END?
113. IS IT POSSIBLE TO CANCEL FILTER EXECUTION?
114. WHAT TYPE OF FILTER DOES OUTPUTCACHEATTRIBUTE CLASS REPRESENTS?
115. WHAT ARE THE EXCEPTION FILTERS IN MVC?

### **6. Dependency Injection**

116. What is Dependency Injection?
117. How to implement Dependency injection in .NET Core?
118. What are the advantages of Dependency Injection in .NET Core?
119. How to use Dependency Injection in Views in ASP.NET Core?
120. What are the types of Service Lifetimes of an object in ASP.NET Core?
121. What is AddSingleton, AddScoped and AddTransient method?

### **7. Configuration & Environment**

122. What are the roles of Appsettings.Json and Launchsetting.Json file?
123. What are the various techniques to save configuration settings in .NET Core?
124. What is Metapackage? What is the name of Metapackage provided by ASP.NET Core?
125. EXPLAIN SESSION AND STATE MANAGEMENT IN ASP.NET CORE.

### **8. Logging & Observability**

126. (No direct questions found in these specific excerpts; related logic exists in middleware examples).

### **9. Entity Framework Core**

127. What is ORM? What are the different types of ORM?
128. What is Entity Framework?
129. How will you differentiate ADO.NET from Entity Framework?
130. How Entity Framework works? OR How to setup EF?
131. What is meant by DBContext and DBSet?
132. What are the different types of application development approaches used with EF?

### **10. LINQ & Expression Trees**

133. What is the difference between IEnumerable and IQueryable in C#?
134. What is the difference between LINQ to SQL and Entity Framework?

### **11. Authentication & Authorization**

135. What are the types of Authentication in ASP.NET MVC?
136. What are the Authentication techniques used to connect to SQL Server?

### **12. Web API Design**

137. (Common categories mentioned in index, specific Web API questions contained in parts of Part I and Part II beyond current excerpt details).

### **13. Async / Await & Concurrency**

138. What is the difference between synchronous and asynchronous programming? What is the role of Task?
139. What is the role of Async and Await?
140. WHAT IS ASYNCHRONOUS PROGRAMMING?

### **14. Multithreading & Parallelism**

141. What is the difference between Process and Thread?
142. Explain Multithreading?
143. What is the difference between Threads and Tasks? What are the advantages of Tasks over Threads?
144. WHY TO USE LOCK STATEMENT?
145. WHAT IS MULTI-TASKING?
146. NAME SOME PROPERTIES OF THREAD CLASS.
147. WHAT THE WAY TO STOP A LONG RUNNING THREAD?
148. WHY WE NEED MULTI-THREADING IN OUR PROJECT?

### **15. Caching & Performance**

149. What is Output Caching in MVC? How to implement it?
150. What is Bundling and Minification in MVC?
151. What are the different types of Caching?
152. What is In-Memory caching & Distributed Caching?
153. EXPLAIN THE CACHING AND RESPONSE CACHING IN ASP.NET CORE.

### **16. Security**

154. How to implement Security in web applications in MVC?
155. What is CORS? Why is CORS restriction is required? How to fix CORS error?

### **17. Microservices & Distributed Systems**

156. (Distributed Caching covered under Caching section Q152).

### **18. Docker & Deployment**

157. What is Kestrel? What is the difference between Kestrel and IIS?
158. What are the types of Hosting in ASP.NET Core? What is In process and Out of process hosting?
159. What are Window Services?

### **19. CI/CD & DevOps**

160. (No specific questions found in these excerpts).

### **20. Design Patterns & SOLID**

161. What is Dependency Inversion Principle?
162. What is DRY principle?
163. What are Design Patterns and what problem they solve?
164. What are the types of Design Patterns?
165. What are Creational Design Patterns?
166. What are Structural Design Patterns?
167. What are Behavioral Design Patterns?
168. What is Singleton Design Pattern?
169. How to make singleton pattern thread safe?
170. What is Factory pattern? Why to use factory pattern?
171. How to implement Factory method pattern?
172. What is Abstract Factory pattern?

### **21. General & Coding Problems**

173. What is the purpose of “using” keyword in C#?
174. Can we use Using keyword with other classes apart from DBConnection?
175. What are Serialization and Deserialization? What are the types of serialization?
176. What is meant by Globalization and Localization?
177. What is Routing in MVC?
178. Explain Attribute Based Routing in MVC?
179. What is the difference between Server.Transfer() and Response.Redirect()?
180. What are the types of state management?
181. What is Routing? Explain attribute routing in ASP.NET Core?
182. What are the must-know pre-requisites for solving basic coding problems?
183. What is the common approach for solving coding problems?
184. Write a function to calculate the sum of all elements in an array.
185. Write a function to calculate the average of an array of numbers.
186. Write a function to find the smallest number in an array.
187. Write a function to find the largest number in an array.
188. Write a function to remove all whitespace characters from a string.
189. IN TRY BLOCK IF WE ADD RETURN STATEMENT WHETHER FINALLY BLOCK IS EXECUTED?
190. WHAT ARE THE TYPES OF DELEGATES?
191. WHAT ARE THE THREE TYPES OF GENERIC DELEGATES?
192. WHAT ARE THE USES OF DELEGATES?
193. WHAT ARE REGULAR EXPRESSIONS?
194. WHAT IS THE DIFFERENCE BETWEEN ADDING ROUTES, TO A WEBFORMS APPLICATION AND TO AN MVC APPLICATION?
