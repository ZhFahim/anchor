"use client";

import { useMutation } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { Upload } from "lucide-react";
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
import { Row, SaveStatus, Section, useSaveStatus } from "./settings-blocks";

const PICTURE_TYPES = ["image/jpeg", "image/png", "image/webp"];

function pictureUploadError(error: Error) {
  if (!(error instanceof HTTPError))
    return "Couldn’t upload the picture. Check your connection.";
  const { status } = error.response;
  if (status === 413 || (status === 400 && /file size/i.test(error.message)))
    return "Couldn’t upload the picture. It’s too big.";
  return "Couldn’t upload the picture.";
}

type PictureRemoval = { picture: string; isCanceled: boolean; isSent: boolean };

// The answer leaves out some of what the stored user has, like hasPassword.
const applyUser = (updated: User) => useAuthStore.getState().mergeUser(updated);

const showPicture = (picture?: string) =>
  useAuthStore.getState().mergeUser({ profileImage: picture });

function sendRemoval(removal: PictureRemoval) {
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
      toast.error("Couldn’t remove the profile picture", {
        retry: () => {
          if (removal.isCanceled) return;
          showPicture();
          sendRemoval(removal);
        },
      });
    },
  );
}

function useProfilePicture() {
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
      toast.success("Profile picture updated");
    },
    onError: (e: Error, _file, replaced) => {
      if (replaced) showPicture(replaced.picture);
      setPictureError(pictureUploadError(e));
    },
  });

  const removePicture = (picture: string) => {
    const removal = { picture, isCanceled: false, isSent: false };
    removalRef.current = removal;
    showPicture();
    toast.success("Profile picture removed", {
      undo: () => {
        removal.isCanceled = true;
        showPicture(picture);
      },
      onClose: () => sendRemoval(removal),
    });
  };

  return { uploadPicture, removePicture, pictureError, setPictureError };
}

export function ProfileSection() {
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
      title="Profile"
      description="How you appear to people you share notes with."
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
                    return setPictureError(
                      "That file isn’t a picture Anchor can use. Pick a JPG, PNG or WebP.",
                    );
                  if (file.size > 5 * 1024 * 1024)
                    return setPictureError(
                      "That picture is over 5 MB. Pick a smaller one.",
                    );
                  setPictureError(null);
                  uploadPicture.mutate(file);
                }}
              />
              <Button
                id={uploadButtonId}
                variant="secondary"
                onClick={() => fileInputRef.current?.click()}
                busy={uploadPicture.isPending && "Uploading…"}
              >
                <Upload aria-hidden />
                Upload a picture
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
                  Remove
                </Button>
              )}
            </div>
            {pictureError ? (
              <FieldError>{pictureError}</FieldError>
            ) : (
              <FieldDescription>JPG, PNG or WebP, up to 5 MB.</FieldDescription>
            )}
          </div>
        </div>
      </Row>
      <Row className="grid grid-cols-2 items-start gap-3.5 max-md:grid-cols-1">
        <Field
          label={
            <span className="flex items-center gap-2.5">
              Name
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
        <Field label="Email" help="Only an admin can change your email.">
          <Input value={user?.email ?? ""} readOnly />
        </Field>
      </Row>
    </Section>
  );
}
