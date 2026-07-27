# 4. Components, Hooks, Forms, and Routing

## Component design mnemonic: **S-M-A-R-T**

- **S - Single purpose.**
- **M - Meaningful API through typed props.**
- **A - Accessible interaction.**
- **R - Reusable only when repetition is real.**
- **T - Testable behavior.**

## Container and presentation separation

```tsx
function ShipmentPage({ shipmentId }: { shipmentId: number }) {
    const { data, isLoading, error } = useGetShipmentQuery(shipmentId);

    if (isLoading) return <Spinner />;
    if (error || !data) return <ErrorMessage />;

    return <ShipmentDetails shipment={data} />;
}

function ShipmentDetails({ shipment }: { shipment: ShipmentDto }) {
    return (
        <section>
            <h1>{shipment.reference}</h1>
            <span>{shipment.status}</span>
        </section>
    );
}
```

> The page handles data state; the presentation component renders typed data. Do not force this split for every tiny component, but it helps when logic and UI become difficult to test or reuse.

## Custom hook example

```tsx
function useAttachmentUpload(driverLoadId: number) {
    const [uploadAttachment, result] = useUploadAttachmentMutation();

    const upload = async (file: File) => {
        if (file.size === 0) {
            throw new Error('Empty files are not allowed');
        }

        const body = new FormData();
        body.append('file', file);

        return uploadAttachment({ driverLoadId, body }).unwrap();
    };

    return { upload, ...result };
}
```

> A custom hook shares logic, not rendered markup. It can combine validation, API mutation, and loading/error state while the component remains focused on interaction.

## Form flow

```text
initial values
  → user edits controlled fields
  → client validation for fast feedback
  → submit disabled while pending
  → server validates again
  → field/business error mapped to UI
  → success navigation/toast/cache refresh
```

> Client validation improves user experience; it is never a security or integrity boundary. The backend must validate authorization, tenant, business state, and persistence constraints.

## Preventing duplicate submission

```tsx
<button disabled={isLoading} onClick={handleSubmit}>
    {isLoading ? 'Saving...' : 'Save'}
</button>
```

> This improves UX, but the server still needs idempotency or concurrency protection because requests can be retried outside the button.

## React Router in dm-web

The application maps public/private route definitions and uses authentication plus roles before rendering private components.

```tsx
<Routes>
    {isAuthenticated ? (
        <Route
            path="/load-board"
            element={isAuthorized ? <LoadBoard /> : <Navigate to="/" />}
        />
    ) : (
        <Route path="/login" element={<Login />} />
    )}
</Routes>
```

### Security correction

> Protected routes improve navigation and user experience, but they do not secure data. A user can call an API without the React app. The ASP.NET Core endpoint must independently authenticate and authorize every protected operation.

## Reusable modal example

```tsx
type ConfirmationModalProps = {
    open: boolean;
    title: string;
    message: string;
    confirmText?: string;
    onConfirm: () => void;
    onCancel: () => void;
};
```

Good reusable components expose intent rather than internal DOM details. For a destructive action, also cover keyboard focus, Escape behavior, labels, disabled/pending state, and error recovery.

## Accessibility basics

- Use semantic buttons, labels, headings, and tables.
- Associate label and form input.
- Keep keyboard interaction and visible focus.
- Do not communicate status using color alone.
- Announce asynchronous success/error where appropriate.
- Add ARIA only when semantic HTML cannot express the behavior.

## Styling in ROD

The project uses Bootstrap and shared CSS/assets. Interview answer:

> I would use the existing design system and utility conventions, keep layout responsive, avoid uncontrolled global overrides, and verify loading, empty, error, and long-content states. Reusability includes behavior and accessibility, not only identical styling.

## Common form cross-questions

**Debounce vs throttle?** Debounce waits for inactivity, useful for search. Throttle limits execution frequency, useful for continuous events such as scroll.

**How do you cancel stale search requests?** Use request cancellation/AbortSignal when supported, or rely on query tooling that tracks the latest subscription; also prevent stale responses from overwriting current results.

**Where should validation live?** Shape/UX on client, business rules on server, integrity in database.

**How handle unsaved changes?** Track dirty state and confirm navigation; do not block after successful save.

