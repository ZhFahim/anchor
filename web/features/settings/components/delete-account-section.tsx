"use client";

import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
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
import { Field, FormAlert } from "@/components/ui/field";
import { PasswordInput } from "@/components/ui/input";
import { toast } from "@/components/ui/toast";
import { deleteAccount } from "@/features/auth/api";
import { useAuthStore } from "@/features/auth/store";
import { Row, RowText, Section } from "./settings-blocks";

export function DeleteAccountSection() {
  const hasPassword = useAuthStore((s) => s.user?.hasPassword !== false);
  const clearAuth = useAuthStore((s) => s.logout);
  const [isOpen, setIsOpen] = React.useState(false);
  const [password, setPassword] = React.useState("");
  const [passwordError, setPasswordError] = React.useState<string | null>(null);
  const [formError, setFormError] = React.useState<string | null>(null);
  const passwordInput = React.useRef<HTMLInputElement>(null);

  const remove = useMutation({
    mutationFn: deleteAccount,
    onSuccess: () => {
      clearAuth({ hasSignedOut: true });
      toast.success("Account deleted");
    },
    onError: (e: Error) => {
      const status = e instanceof HTTPError ? e.response.status : 0;
      if (status === 403) {
        setPassword("");
        setPasswordError("That isn’t your password.");
        passwordInput.current?.focus();
      } else if (status === 409) {
        setFormError(
          "You’re the only admin on this server. Make someone else an admin first.",
        );
      } else {
        setFormError(
          status
            ? "Couldn’t delete your account. Try again in a moment."
            : "Couldn’t reach the server. Check your connection and try again.",
        );
      }
    },
  });

  React.useEffect(() => {
    if (!isOpen) return;
    setPassword("");
    setPasswordError(null);
    setFormError(null);
  }, [isOpen]);

  return (
    <Section id="delete-account" title="Delete account">
      <Row>
        <RowText
          title="This can’t be undone"
          text="Permanently delete your account and everything in it from this server. To keep a copy of your notes, export them first."
        />
        <Button variant="danger" onClick={() => setIsOpen(true)}>
          Delete account
        </Button>
      </Row>
      <Dialog
        open={isOpen}
        onOpenChange={(next) => !remove.isPending && setIsOpen(next)}
      >
        <DialogContent
          alert
          showClose={false}
          onEscapeKeyDown={(e) => remove.isPending && e.preventDefault()}
        >
          <form
            className="contents"
            onSubmit={(e) => {
              e.preventDefault();
              setFormError(null);
              remove.mutate(hasPassword ? password : undefined);
            }}
          >
            <DialogHeader>
              <DialogTitle className="pr-0">Delete your account?</DialogTitle>
              <DialogDescription>
                This can’t be undone. Your account, notes, tags, attachments and
                reminders will be permanently deleted from this server. Notes
                you shared will no longer be available to other people.
              </DialogDescription>
            </DialogHeader>
            {(hasPassword || formError) && (
              <DialogBody>
                {hasPassword && (
                  <Field
                    label="Password"
                    help="Enter your password to confirm."
                    error={passwordError}
                  >
                    <PasswordInput
                      ref={passwordInput}
                      value={password}
                      autoComplete="current-password"
                      autoFocus
                      onChange={(e) => {
                        setPassword(e.target.value);
                        setPasswordError(null);
                      }}
                    />
                  </Field>
                )}
                {formError && <FormAlert>{formError}</FormAlert>}
              </DialogBody>
            )}
            <DialogFooter>
              <Button
                type="button"
                variant="quiet"
                onClick={() => setIsOpen(false)}
                disabled={remove.isPending}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                variant="destructive"
                disabled={hasPassword && !password}
                busy={remove.isPending && "Deleting…"}
              >
                Delete account
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </Section>
  );
}
