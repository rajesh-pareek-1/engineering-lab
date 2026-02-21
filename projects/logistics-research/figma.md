Mobile & Web App Figma + SRS Flow : https://pink-benita-10.tiiny.site/

GPT response for final figma for mvp:

# 📘 SOFTWARE REQUIREMENTS SPECIFICATION (SRS)

## Product: Logistics Shipment POD Tracking System

## Version: MVP 1.0

---

# 1. INTRODUCTION

## 1.1 Purpose

This document defines requirements for a minimal logistics shipment tracking system that allows:

* Transporters to create shipments
* Assign shipments to truckers
* Truckers to assign drivers
* Drivers to upload POD (Proof of Delivery)
* System to generate public share link for POD viewing

This is a  **lean MVP** , focused only on shipment lifecycle + POD sharing.

---

## 1.2 Scope (MVP Only)

The system will support:

* Role-based login
* Shipment creation
* Assignment workflow
* POD image upload
* Public POD viewing link

Out of Scope (Phase 2+):

* Payment systems
* Live GPS tracking
* Analytics dashboard
* Notifications
* Complex filters/search
* Multi-document upload
* Shipment editing after sharing

---

# 2. USER ROLES

### 2.1 Transporter

Can:

* Create shipment
* Assign trucker
* View shipment details
* Generate POD share link

---

### 2.2 Trucker

Can:

* View assigned shipments
* Assign driver + vehicle
* View POD

Cannot:

* Create shipment
* Generate share link

---

### 2.3 Driver

Can:

* View assigned shipments
* Upload POD image

Cannot:

* Assign trucker
* Generate share link

---

### 2.4 Broker (Public User)

Can:

* View shared POD via public URL
* Download POD image

No login required.

---

# 3. FUNCTIONAL REQUIREMENTS

---

# 3.1 Authentication

FR-1: System shall allow login via email + password.
FR-2: System shall determine role after login.
FR-3: Role determines visible screens and actions.

---

# 3.2 Shipment Creation

FR-4: Transporter shall create shipment with:

* Shipment Number (required)
* Shipper Name (optional)

FR-5: System shall assign default status = "Created".

FR-6: Shipment number must be unique per transporter.

---

# 3.3 Shipment Assignment

FR-7: Transporter can assign a trucker to a shipment.
FR-8: When trucker is assigned, status changes to "Assigned".

---

# 3.4 Driver Assignment

FR-9: Trucker can assign:

* Driver
* Vehicle Number

FR-10: Once assigned, driver sees shipment in their list.

---

# 3.5 POD Upload

FR-11: Driver can upload a single image as POD.
FR-12: After upload:

* Status becomes "POD Uploaded"
* Upload timestamp stored

FR-13: Image must be stored securely in server storage (e.g., S3 or equivalent).

---

# 3.6 Share Link Generation

FR-14: Transporter can generate share link only if POD exists.
FR-15: System generates secure public URL.
FR-16: Share link expires after 30 days.
FR-17: Status becomes "Shared".

---

# 3.7 Public POD View Page

FR-18: Public page shall display:

* Shipment Number
* Vehicle Number
* Transporter Name
* POD Image
* Download Button

FR-19: No authentication required.

FR-20: Expired link shows “Link Expired” message.

---

# 4. SHIPMENT STATUS FLOW

Status lifecycle:

Created
→ Assigned
→ POD Uploaded
→ Shared

System must prevent invalid transitions.

Example:
Driver cannot upload if not assigned.

---

# 5. NON-FUNCTIONAL REQUIREMENTS

---

## 5.1 Performance

* Page load < 2 seconds
* Image upload < 5 seconds (under 5MB)

---

## 5.2 Security

* Role-based access control
* Public link must use unique token
* Token must be unguessable
* Image storage private (except via signed URL)

---

## 5.3 Usability

* Mobile-first design
* Large tap targets
* Minimal text
* No complex filters
* Max 3 taps to upload POD

---

## 5.4 Scalability (Basic)

* Should support 10,000 shipments without degradation
* Database indexed on shipment number

---

# 6. DATABASE ENTITIES (MVP)

---

## User

* id
* name
* email
* password_hash
* role (transporter, trucker, driver)

---

## Shipment

* id
* shipment_number
* shipper_name
* transporter_id
* trucker_id (nullable)
* driver_id (nullable)
* vehicle_number (nullable)
* status
* pod_image_url (nullable)
* pod_uploaded_at
* share_token (nullable)
* share_expiry_date

---

# 7. VALIDATION RULES

* Shipment number required
* Only transporter can create shipment
* Only trucker can assign driver
* Only driver can upload POD
* Share link only if POD exists

---

# 8. EDGE CASES

* Driver tries uploading twice → overwrite allowed
* Share link regenerated → old link invalid
* Truck reassignment after POD → not allowed in MVP

---

# 9. SUCCESS METRICS (MVP VALIDATION)

* Time to create shipment < 30 seconds
* POD upload completion rate > 80%
* Share link generation success rate 100%

---

# 10. FUTURE PHASE (Not in MVP)

* GPS tracking
* Multiple POD uploads
* E-way bill attachment
* Notification system
* Analytics dashboard
* Shipment search + filters
* Role-based dashboards
