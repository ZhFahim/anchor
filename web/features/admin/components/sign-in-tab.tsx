"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { DoorOpen, Lock, UserCheck } from "lucide-react";
import { useTranslations } from "next-intl";
import type { ReactNode } from "react";
import { LoadFailedRow } from "@/components/ui/empty-state";
import { RadioCards } from "@/components/ui/radio-cards";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "@/components/ui/toast";
import {
  SaveStatus,
  SectionHeader,
  useSaveStatus,
} from "@/features/settings/components/settings-blocks";
import { useRetry } from "@/lib/hooks/use-retry";
import { getRegistrationSettings, updateRegistrationMode } from "../api";
import { adminKeys } from "../queries";
import type { RegistrationMode } from "../types";
import { LockNote } from "./admin-parts";
import { SingleSignOn } from "./single-sign-on";

const code = (chunks: ReactNode) => <code>{chunks}</code>;

export function SignInTab({ hidden }: { hidden?: boolean }) {
  const t = useTranslations();
  const queryClient = useQueryClient();
  const registration = useQuery({
    queryKey: adminKeys.registration,
    queryFn: getRegistrationSettings,
  });
  const registrationRetry = useRetry(registration.refetch);
  const [registrationSaveState, setRegistrationSaveState] = useSaveStatus();

  const saveMode = useMutation({
    mutationFn: (mode: RegistrationMode) => updateRegistrationMode({ mode }),
    onMutate: (mode) => {
      const before = queryClient.getQueryData(adminKeys.registration);
      queryClient.setQueryData(
        adminKeys.registration,
        (prev: object | undefined) => (prev ? { ...prev, mode } : prev),
      );
      return { before };
    },
    onSuccess: () => {
      setRegistrationSaveState("saved");
      queryClient.invalidateQueries({
        queryKey: adminKeys.pendingUsers,
      });
    },
    onError: (_, mode, context) => {
      queryClient.setQueryData(adminKeys.registration, context?.before);
      toast.error(t("adminSignupChangeFailed"), {
        retry: () => saveMode.mutate(mode),
      });
    },
  });
  const locked = !!registration.data?.isLocked;

  return (
    <div hidden={hidden} className="grid max-w-180 gap-6.5">
      <section className="grid gap-2.5">
        <SectionHeader
          title={t("adminWhoCanSignUp")}
          description={t("adminWhoCanSignUpHelp")}
          saved={<SaveStatus state={registrationSaveState} />}
        />
        {locked && (
          <LockNote>
            {t.rich("adminSignupLocked", { variable: "USER_SIGNUP", code })}
          </LockNote>
        )}
        {(registration.isError && !registration.data) ||
        registrationRetry.isRetrying ? (
          <LoadFailedRow
            message={t("adminSignupLoadFailed")}
            onRetry={registrationRetry.retry}
            isRetrying={registrationRetry.isRetrying}
          />
        ) : registration.isLoading ? (
          <Skeleton className="h-22 w-full rounded-xl" />
        ) : (
          <RadioCards
            aria-label={t("adminWhoCanSignUp")}
            value={registration.data?.mode ?? "enabled"}
            onValueChange={(mode) => saveMode.mutate(mode)}
            className="grid-cols-3 max-md:grid-cols-1"
            options={[
              {
                value: "enabled",
                label: t("adminSignupOpen"),
                icon: <DoorOpen />,
                description: t("adminSignupOpenHelp"),
                disabled: locked,
              },
              {
                value: "review",
                label: t("adminSignupReview"),
                icon: <UserCheck />,
                description: t("adminSignupReviewHelp"),
                disabled: locked,
              },
              {
                value: "disabled",
                label: t("adminSignupClosed"),
                icon: <Lock />,
                description: t("adminSignupClosedHelp"),
                disabled: locked,
              },
            ]}
          />
        )}
      </section>
      <SingleSignOn isHidden={hidden} />
    </div>
  );
}
