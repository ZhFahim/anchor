"use client";

import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { KeyRound } from "lucide-react";
import * as React from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogBody,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field } from "@/components/ui/field";
import { Input, InputButton } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { toast } from "@/components/ui/toast";
import {
  ACCOUNT_FIELD_HELP,
  type AccountField,
  NAME_MAX_LENGTH,
  refusedField,
} from "@/features/auth/account-fields";
import { useAuthStore } from "@/features/auth/store";
import { copyText } from "@/lib/clipboard";
import { useLastShown } from "@/lib/hooks/use-last-shown";
import { firstName } from "@/lib/utils";
import { createUser, updateUser } from "../api";
import type { AdminUser } from "../types";

const isEmailTaken = (error: Error) =>
  error instanceof HTTPError && error.response.status === 409;
const EMAIL_TAKEN = "An account with this email already exists.";

const couldWorkLater = (error: Error) =>
  !(error instanceof HTTPError) || error.response.status >= 500;

type PersonErrors = Partial<Record<AccountField, string>>;

function makePassword() {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  return [...bytes].map((b) => alphabet[b % alphabet.length]).join("");
}

export function AddPersonDialog({
  open,
  onOpenChange,
  onDone,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onDone: () => void;
}) {
  const [name, setName] = React.useState("");
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [errors, setErrors] = React.useState<PersonErrors>({});
  const refs = {
    name: React.useRef<HTMLInputElement>(null),
    email: React.useRef<HTMLInputElement>(null),
    password: React.useRef<HTMLInputElement>(null),
  };
  const showError = (field: AccountField, message: string) => {
    setErrors({ [field]: message });
    refs[field].current?.focus();
  };
  const create = useMutation({
    mutationFn: createUser,
    onSuccess: (user) => {
      onDone();
      onOpenChange(false);
      toast.success(`${firstName(user.name)} can sign in now`);
    },
    onError: (e: Error, dto) => {
      const field = refusedField(e);
      if (isEmailTaken(e)) showError("email", EMAIL_TAKEN);
      else if (field) showError(field, ACCOUNT_FIELD_HELP[field]);
      else
        toast.error(
          `Couldn’t add ${firstName(dto.name)}`,
          couldWorkLater(e) ? { retry: () => create.mutate(dto) } : undefined,
        );
    },
  });
  React.useEffect(() => {
    if (!open) return;
    setName("");
    setEmail("");
    setPassword("");
    setErrors({});
  }, [open]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <form
          className="contents"
          onSubmit={(e) => {
            e.preventDefault();
            if (!name.trim()) return showError("name", "Enter their name.");
            create.mutate({ name: name.trim(), email: email.trim(), password });
          }}
        >
          <DialogHeader>
            <DialogTitle>Add a person</DialogTitle>
            <DialogDescription>
              They can sign in right away and change their password in Settings.
            </DialogDescription>
          </DialogHeader>
          <DialogBody>
            <Field label="Name" error={errors.name}>
              <Input
                ref={refs.name}
                value={name}
                maxLength={NAME_MAX_LENGTH}
                onChange={(e) => {
                  setName(e.target.value);
                  setErrors((prev) => ({ ...prev, name: undefined }));
                }}
                placeholder="Their name"
                autoFocus
              />
            </Field>
            <Field label="Email" error={errors.email}>
              <Input
                ref={refs.email}
                type="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value);
                  setErrors((prev) => ({ ...prev, email: undefined }));
                }}
                placeholder="name@example.com"
                required
              />
            </Field>
            <Field label="Password" error={errors.password}>
              <Input
                ref={refs.password}
                mono
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  setErrors((prev) => ({ ...prev, password: undefined }));
                }}
                placeholder="At least 8 characters"
                minLength={8}
                required
                end={
                  <InputButton onClick={() => setPassword(makePassword())}>
                    Generate
                  </InputButton>
                }
              />
            </Field>
          </DialogBody>
          <DialogFooter>
            <Button
              type="button"
              variant="quiet"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={!email.trim() || password.length < 8}
              busy={create.isPending && "Adding…"}
            >
              Add person
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export function EditPersonDialog({
  user,
  isSelf,
  onClose,
  onDone,
}: {
  user: AdminUser | null;
  isSelf: boolean;
  onClose: () => void;
  onDone: () => void;
}) {
  const shownUser = useLastShown(user, !!user);
  const isShownSelf = useLastShown(isSelf, !!user);
  const [name, setName] = React.useState("");
  const [email, setEmail] = React.useState("");
  const [isAdmin, setIsAdmin] = React.useState(false);
  const [errors, setErrors] = React.useState<PersonErrors>({});
  const nameRef = React.useRef<HTMLInputElement>(null);
  const emailRef = React.useRef<HTMLInputElement>(null);
  const showError = (field: "name" | "email", message: string) => {
    setErrors({ [field]: message });
    (field === "name" ? nameRef : emailRef).current?.focus();
  };
  React.useEffect(() => {
    if (!user) return;
    setName(user.name);
    setEmail(user.email);
    setIsAdmin(user.isAdmin);
    setErrors({});
  }, [user]);
  const save = useMutation({
    mutationFn: () =>
      updateUser(user?.id as string, {
        name: name.trim(),
        email: email.trim(),
        ...(isSelf ? {} : { isAdmin }),
      }),
    onSuccess: (updated) => {
      const { user: signedIn, mergeUser } = useAuthStore.getState();
      if (signedIn?.id === updated.id)
        mergeUser({ name: updated.name, email: updated.email });
      onDone();
      onClose();
      toast.success("Saved");
    },
    onError: (e: Error) => {
      const field = refusedField(e);
      if (isEmailTaken(e)) showError("email", EMAIL_TAKEN);
      else if (field === "name" || field === "email")
        showError(field, ACCOUNT_FIELD_HELP[field]);
      else
        toast.error(
          "Couldn’t save the changes",
          couldWorkLater(e) ? { retry: () => save.mutate() } : undefined,
        );
    },
  });
  return (
    <Dialog open={!!user} onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <form
          className="contents"
          onSubmit={(e) => {
            e.preventDefault();
            if (!name.trim()) return showError("name", "Enter their name.");
            save.mutate();
          }}
        >
          <DialogHeader>
            <DialogTitle>Edit {shownUser?.name}</DialogTitle>
          </DialogHeader>
          <DialogBody>
            <Field label="Name" error={errors.name}>
              <Input
                ref={nameRef}
                value={name}
                maxLength={NAME_MAX_LENGTH}
                onChange={(e) => {
                  setName(e.target.value);
                  setErrors((prev) => ({ ...prev, name: undefined }));
                }}
              />
            </Field>
            <Field label="Email" error={errors.email}>
              <Input
                ref={emailRef}
                type="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value);
                  setErrors((prev) => ({ ...prev, email: undefined }));
                }}
                required
              />
            </Field>
            <div className="flex items-center gap-4 pt-1">
              <div className="grid flex-1 gap-0.5">
                <label htmlFor="edit-admin" className="font-semibold text-ui">
                  Admin
                </label>
                <span className="text-meta text-muted-foreground">
                  {isShownSelf
                    ? "You can’t change your own role. Another admin can."
                    : "Can add people and change sign-in settings."}
                </span>
              </div>
              <Switch
                id="edit-admin"
                checked={isAdmin}
                disabled={isShownSelf}
                onCheckedChange={setIsAdmin}
              />
            </div>
          </DialogBody>
          <DialogFooter>
            <Button type="button" variant="quiet" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" busy={save.isPending && "Saving…"}>
              Save
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export function NewPasswordDialog({
  value,
  onClose,
}: {
  value: { user: AdminUser; password: string } | null;
  onClose: () => void;
}) {
  const shown = useLastShown(value, !!value);
  const [copied, setCopied] = React.useState(false);
  // biome-ignore lint/correctness/useExhaustiveDependencies: each new password starts with Copy
  React.useEffect(() => setCopied(false), [shown]);
  const name = firstName(shown?.user.name ?? "");
  return (
    <Dialog open={!!value} onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New password for {name}</DialogTitle>
          <DialogDescription>
            Share it with {name} securely. It won’t be shown again.
          </DialogDescription>
        </DialogHeader>
        <DialogBody>
          <Input
            readOnly
            mono
            aria-label={`New password for ${name}`}
            value={shown?.password ?? ""}
            icon={<KeyRound aria-hidden />}
            end={
              <InputButton
                onClick={() =>
                  copyText(shown?.password ?? "").then(
                    () => setCopied(true),
                    () => toast.error("Couldn’t copy the password"),
                  )
                }
              >
                {copied ? "Copied" : "Copy"}
              </InputButton>
            }
          />
        </DialogBody>
        <DialogFooter>
          <Button onClick={onClose}>Done</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
