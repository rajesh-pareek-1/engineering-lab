Perfect.

Now we design this properly — structured, clean, zero confusion.

You chose:

Structured hierarchy (Transporter → Trucker → Driver)

Multiple shipments per trucker

Mobile app (role-based views)

Pure stack navigation

Web-only broker link

Good. Now let’s design Figma wireframe structure aligned 100% with your locked SRS + real-world flow.

---

# 🧱 ROLE-BASED APP STRUCTURE (Single App, Role-Aware UI)

One mobile app.
After OTP login → system detects role → loads role stack.

No separate apps.

---

# 1️⃣ TRANSPORTER FLOW (Stack Navigation)

### Screen 1: Login (OTP)

* Phone number
* OTP verify

↓

### Screen 2: Shipment List (Dashboard)

List view (scrollable)

Each card shows:

* Shipment Number
* Assigned Trucker (or “Not Assigned”)
* Driver (if assigned)
* Vehicle Number
* Status Badge (Created / Assigned / POD Uploaded / Shared)
* Last Updated

Top Right:

* Create Shipment

↓

### Screen 3: Create Shipment

Fields:

* Shipment Number (manual)
* Optional: Shipper Name (text only)

Button:
Create

On submit → Status = Created

↓

### Screen 4: Shipment Detail (Transporter View)

Sections:

Header:

* Shipment Number
* Status Badge

Assignment Section:

* Assigned Trucker (Select dropdown)
* Button: Assign Trucker

Driver Section:

* Driver Name (visible once assigned by trucker)
* Vehicle Number

POD Section:

* Image preview (if uploaded)
* Timestamp

Bottom Button (if POD uploaded):
Share Link

↓

### Screen 5: Share Confirmation Modal

* Generated Link (Copy button)
* “Link expires in 30 days”

Status changes → Shared

---

# 2️⃣ TRUCKER FLOW (List-Based Dashboard)

### Screen 1: Login (OTP)

↓

### Screen 2: Assigned Shipments List

Each card:

* Shipment Number
* Transporter Name
* Driver (if assigned)
* Status

↓

### Screen 3: Shipment Detail (Trucker View)

Header:

* Shipment Number
* Status

Assignment Section:

* Select Driver (Dropdown or type phone)
* Enter Vehicle Number

Button:
Assign Driver

After driver assignment → Shipment status remains Assigned.

If POD uploaded:

* Show image preview

Trucker cannot share.
Cannot change shipment owner.

---

# 3️⃣ DRIVER FLOW (Ultra Minimal)

### Screen 1: Login (OTP)

↓

### Screen 2: My Shipments

List view (likely 1–3 max)

Each card:

* Shipment Number
* Vehicle Number
* Upload Button (if not uploaded)

↓

### Screen 3: Upload POD

* Open Camera
* Retake option
* Confirm Upload

After upload:

* Success screen
* Back to list

Status becomes: POD Uploaded

---

# 4️⃣ BROKER / SHIPPER WEB VIEW (Very Narrow Web App)

Simple page:

Header:
Shipment Number
Vehicle Number
Transporter Name

Body:
POD Image (Full view)
Download Button

No login.
No navigation.
Single page only.

---

# 🔄 COMPLETE STATE ALIGNMENT

Created
→ Assigned (Transporter assigns trucker)
→ Assigned + Driver Assigned (internally)
→ POD Uploaded (Driver uploads)
→ Shared (Transporter generates link)

No backward state transitions.

---

# 🎨 Figma Design Principles

Keep UI:

• Heavy typography
• Big buttons
• Large status badges
• No complex filtering
• No hamburger menus
• No bottom tabs
• No advanced search

Stack only:
List → Detail → Action → Back

That’s it.

---

# 🧠 Important UX Constraint

This app must feel:

Faster than:
Camera → WhatsApp → Select Contact → Send

If upload takes longer than that,
you lose.

---

# 📦 Final Screen Count (Entire MVP)

Transporter: 5 screens
Trucker: 3 screens
Driver: 3 screens
Broker Web: 1 page

Total:
~12–13 screens.

That is perfectly buildable in 3–4 weeks.

---

# 🚀 Next Step

Now we choose:

Do you want:
A) Low-fidelity wireframe layout breakdown (box-by-box placement)
or
B) Exact Figma component structure (Auto Layout, reusable components, design system thinking)

Pick one and we go surgical.
