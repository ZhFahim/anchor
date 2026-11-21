"use client";

import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { KeyRound } from "lucide-react";
import { useTranslations } from "next-intl";
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
  type AccountField,
  accountFieldHelp,
  NAME_MAX_LENGTH,
  PASSWORD_MIN_LENGTH,
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
  const t = useTranslations();
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
      toast.success(t("adminCanSignIn", { name: firstName(user.name) }));
    },
    onError: (e: Error, dto) => {
      const field = refusedField(e);
      if (isEmailTaken(e)) showError("email", t("adminEmailTaken"));
      else if (field) showError(field, accountFieldHelp(t, field));
      else
        toast.error(
          t("adminAddFailed", { name: firstName(dto.name) }),
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
            if (!name.trim()) return showError("name", t("adminEnterName"));
            create.mutate({ name: name.trim(), email: email.trim(), password });
          }}
        >
          <DialogHeader>
            <DialogTitle>{t("adminAddPersonTitle")}</DialogTitle>
            <DialogDescription>{t("adminAddPersonMessage")}</DialogDescription>
          </DialogHeader>
          <DialogBody>
            <Field label={t("adminName")} error={errors.name}>
              <Input
                ref={refs.name}
                value={name}
                maxLength={NAME_MAX_LENGTH}
                onChange={(e) => {
                  setName(e.target.value);
                  setErrors((prev) => ({ ...prev, name: undefined }));
                }}
                placeholder={t("adminNamePlaceholder")}
                autoFocus
              />
            </Field>
            <Field label={t("adminEmail")} error={errors.email}>
              <Input
                ref={refs.email}
                type="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value);
                  setErrors((prev) => ({ ...prev, email: undefined }));
                }}
                placeholder={t("adminEmailPlaceholder")}
                required
              />
            </Field>
            <Field label={t("adminPassword")} error={errors.password}>
              <Input
                ref={refs.password}
                mono
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  setErrors((prev) => ({ ...prev, password: undefined }));
                }}
                placeholder={t("adminPasswordPlaceholder", {
                  count: PASSWORD_MIN_LENGTH,
                })}
                minLength={PASSWORD_MIN_LENGTH}
                required
                end={
                  <InputButton onClick={() => setPassword(makePassword())}>
                    {t("adminGeneratePassword")}
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
              {t("commonCancel")}
            </Button>
            <Button
              type="submit"
              disabled={!email.trim() || password.length < PASSWORD_MIN_LENGTH}
              busy={create.isPending && t("adminAdding")}
            >
              {t("adminAddPerson")}
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
  const t = useTranslations();
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
      toast.success(t("uiSaved"));
    },
    onError: (e: Error) => {
      const field = refusedField(e);
      if (isEmailTaken(e)) showError("email", t("adminEmailTaken"));
      else if (field === "name" || field === "email")
        showError(field, accountFieldHelp(t, field));
      else
        toast.error(
          t("adminSaveFailed"),
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
            if (!name.trim()) return showError("name", t("adminEnterName"));
            save.mutate();
          }}
        >
          <DialogHeader>
            <DialogTitle>
              {t("adminEditTitle", { name: shownUser?.name ?? "" })}
            </DialogTitle>
          </DialogHeader>
          <DialogBody>
            <Field label={t("adminName")} error={errors.name}>
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
            <Field label={t("adminEmail")} error={errors.email}>
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
                  {t("adminRoleAdmin")}
                </label>
                <span className="text-meta text-muted-foreground">
                  {isShownSelf ? t("adminOwnRole") : t("adminRoleHelp")}
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
              {t("commonCancel")}
            </Button>
            <Button type="submit" busy={save.isPending && t("uiSaving")}>
              {t("commonSave")}
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
  const t = useTranslations();
  const shown = useLastShown(value, !!value);
  const [copied, setCopied] = React.useState(false);
  // biome-ignore lint/correctness/useExhaustiveDependencies: each new password starts with Copy
  React.useEffect(() => setCopied(false), [shown]);
  const name = firstName(shown?.user.name ?? "");
  return (
    <Dialog open={!!value} onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t("adminNewPasswordTitle", { name })}</DialogTitle>
          <DialogDescription>
            {t("adminNewPasswordMessage", { name })}
          </DialogDescription>
        </DialogHeader>
        <DialogBody>
          <Input
            readOnly
            mono
            aria-label={t("adminNewPasswordTitle", { name })}
            value={shown?.password ?? ""}
            icon={<KeyRound aria-hidden />}
            end={
              <InputButton
                onClick={() =>
                  copyText(shown?.password ?? "").then(
                    () => setCopied(true),
                    () => toast.error(t("adminCopyPasswordFailed")),
                  )
                }
              >
                {copied ? t("commonCopied") : t("commonCopy")}
              </InputButton>
            }
          />
        </DialogBody>
        <DialogFooter>
          <Button onClick={onClose}>{t("commonDone")}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
