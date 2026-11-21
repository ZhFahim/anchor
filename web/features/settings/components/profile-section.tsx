"use client";

import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { Upload } from "lucide-react";
import { useTranslations } from "next-intl";
import * as React from "react";
import { Avatar, preloadPhoto } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Field, FieldDescription, FieldError } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { toast } from "@/components/ui/toast";
import {
  removeProfileImage,
  updateProfile,
  uploadProfileImage,
} from "@/features/auth/api";
import { useAuthStore } from "@/features/auth/store";
import type { User } from "@/features/auth/types";
import type { Translate } from "@/i18n/translate";
import { errorCodeOf } from "@/lib/api/error-code";
import { Row, SaveStatus, Section, useSaveStatus } from "./settings-blocks";

const PICTURE_TYPES = ["image/jpeg", "image/png", "image/webp"];
const PICTURE_MAX_MB = 5;

function pictureUploadError(error: Error, t: Translate) {
  if (!(error instanceof HTTPError)) return t("settingsPictureUploadOffline");
  const { status } = error.response;
  if (status === 413 || errorCodeOf(error) === "FILE_TOO_LARGE")
    return t("settingsPictureTooBig");
  return t("settingsPictureUploadFailed");
}

type PictureRemoval = { picture: string; isCanceled: boolean; isSent: boolean };

// The answer leaves out some of what the stored user has, like hasPassword.
const applyUser = (updated: User) => useAuthStore.getState().mergeUser(updated);

const showPicture = (picture?: string) =>
  useAuthStore.getState().mergeUser({ profileImage: picture });

function sendRemoval(removal: PictureRemoval, t: Translate) {
  if (removal.isCanceled) return;
  removal.isSent = true;
  removeProfileImage().then(
    (updated) => {
      if (!removal.isCanceled) applyUser(updated);
    },
    () => {
      removal.isSent = false;
      if (removal.isCanceled) return;
      showPicture(removal.picture);
      toast.error(t("settingsPictureRemoveFailed"), {
        retry: () => {
          if (removal.isCanceled) return;
          showPicture();
          sendRemoval(removal, t);
        },
      });
    },
  );
}

function useProfilePicture() {
  const t = useTranslations();
  const [pictureError, setPictureError] = React.useState<string | null>(null);
  const removalRef = React.useRef<PictureRemoval | null>(null);

  const uploadPicture = useMutation({
    mutationFn: uploadProfileImage,
    onMutate: () => {
      const removal = removalRef.current;
      if (!removal || removal.isSent || removal.isCanceled) return;
      removal.isCanceled = true;
      return { picture: removal.picture };
    },
    onSuccess: async (updated) => {
      if (updated.profileImage) await preloadPhoto(updated.profileImage);
      applyUser(updated);
      toast.success(t("settingsPictureUpdated"));
    },
    onError: (e: Error, _file, replaced) => {
      if (replaced) showPicture(replaced.picture);
      setPictureError(pictureUploadError(e, t));
    },
  });

  const removePicture = (picture: string) => {
    const removal = { picture, isCanceled: false, isSent: false };
    removalRef.current = removal;
    showPicture();
    toast.success(t("settingsPictureRemoved"), {
      undo: () => {
        removal.isCanceled = true;
        showPicture(picture);
      },
      onClose: () => sendRemoval(removal, t),
    });
  };

  return { uploadPicture, removePicture, pictureError, setPictureError };
}

export function ProfileSection() {
  const t = useTranslations();
  const user = useAuthStore((s) => s.user);
  const fileInputRef = React.useRef<HTMLInputElement>(null);
  const uploadButtonId = React.useId();
  const removeButtonId = React.useId();
  const [name, setName] = React.useState(user?.name ?? "");
  const [nameState, setNameState] = useSaveStatus();
  const { uploadPicture, removePicture, pictureError, setPictureError } =
    useProfilePicture();

  React.useEffect(() => {
    if (user?.name !== undefined) setName(user.name);
  }, [user?.name]);

  const saveName = useMutation({
    mutationFn: (value: string) => updateProfile({ name: value }),
    onMutate: () => setNameState("saving"),
    onSuccess: (updated) => {
      applyUser(updated);
      setNameState("saved");
    },
    onError: () => setNameState("failed"),
  });

  const profileImage = user?.profileImage;

  const commitName = () => {
    const value = name.trim();
    const savedName = user?.name ?? "";
    if (!value) {
      setName(savedName);
      setNameState("idle");
      return;
    }
    if (value === savedName) return;
    if (saveName.isPending && saveName.variables === value) return;
    saveName.mutate(value);
  };

  return (
    <Section
      id="profile"
      title={t("settingsProfile")}
      description={t("settingsProfileHelp")}
    >
      <Row>
        <div className="flex flex-wrap items-center gap-5">
          <Avatar
            id={user?.id ?? ""}
            name={user?.name || user?.email || "?"}
            src={profileImage}
            size="xl"
            className="shadow-[0_0_0_4px_var(--card),0_0_0_5px_color-mix(in_srgb,var(--border)_70%,transparent)]"
          />
          <div className="grid gap-2">
            <div className="flex flex-wrap gap-2">
              <input
                ref={fileInputRef}
                type="file"
                hidden
                accept={PICTURE_TYPES.join(",")}
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  e.target.value = "";
                  if (!file) return;
                  if (!PICTURE_TYPES.includes(file.type))
                    return setPictureError(t("settingsPictureWrongType"));
                  if (file.size >= PICTURE_MAX_MB * 1024 * 1024)
                    return setPictureError(
                      t("settingsPictureOverLimit", {
                        megabytes: PICTURE_MAX_MB,
                      }),
                    );
                  setPictureError(null);
                  uploadPicture.mutate(file);
                }}
              />
              <Button
                id={uploadButtonId}
                variant="secondary"
                onClick={() => fileInputRef.current?.click()}
                busy={uploadPicture.isPending && t("settingsUploading")}
              >
                <Upload aria-hidden />
                {t("settingsUploadPicture")}
              </Button>
              {profileImage && (
                <Button
                  id={removeButtonId}
                  variant="quiet"
                  onClick={() => {
                    if (document.activeElement?.id === removeButtonId)
                      document.getElementById(uploadButtonId)?.focus();
                    removePicture(profileImage);
                  }}
                >
                  {t("commonRemove")}
                </Button>
              )}
            </div>
            {pictureError ? (
              <FieldError>{pictureError}</FieldError>
            ) : (
              <FieldDescription>
                {t("settingsPictureHelp", { megabytes: PICTURE_MAX_MB })}
              </FieldDescription>
            )}
          </div>
        </div>
      </Row>
      <Row className="grid grid-cols-2 items-start gap-3.5 max-md:grid-cols-1">
        <Field
          label={
            <span className="flex items-center gap-2.5">
              {t("settingsName")}
              <SaveStatus state={nameState} onRetry={commitName} />
            </span>
          }
        >
          <Input
            value={name}
            maxLength={100}
            autoComplete="name"
            onChange={(e) => setName(e.target.value)}
            onBlur={commitName}
            onKeyDown={(e) => {
              if (e.key === "Enter") commitName();
            }}
          />
        </Field>
        <Field label={t("settingsEmail")} help={t("settingsEmailHelp")}>
          <Input value={user?.email ?? ""} readOnly />
        </Field>
      </Row>
    </Section>
  );
}
