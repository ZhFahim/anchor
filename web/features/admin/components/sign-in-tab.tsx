"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { DoorOpen, Lock, UserCheck } from "lucide-react";
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

export function SignInTab({ hidden }: { hidden?: boolean }) {
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
      toast.error("Couldn’t change who can sign up", {
        retry: () => saveMode.mutate(mode),
      });
    },
  });
  const locked = !!registration.data?.isLocked;

  return (
    <div hidden={hidden} className="grid max-w-180 gap-6.5">
      <section className="grid gap-2.5">
        <SectionHeader
          title="Who can sign up"
          description="Choose who can create an account."
          saved={<SaveStatus state={registrationSaveState} />}
        />
        {locked && (
          <LockNote>
            Set by <code>USER_SIGNUP</code> on the server. Remove it there to
            change it here.
          </LockNote>
        )}
        {(registration.isError && !registration.data) ||
        registrationRetry.isRetrying ? (
          <LoadFailedRow
            message="Couldn’t load who can sign up."
            onRetry={registrationRetry.retry}
            isRetrying={registrationRetry.isRetrying}
          />
        ) : registration.isLoading ? (
          <Skeleton className="h-22 w-full rounded-xl" />
        ) : (
          <RadioCards
            aria-label="Who can sign up"
            value={registration.data?.mode ?? "enabled"}
            onValueChange={(mode) => saveMode.mutate(mode)}
            className="grid-cols-3 max-md:grid-cols-1"
            options={[
              {
                value: "enabled",
                label: "Open",
                icon: <DoorOpen />,
                description: "Anyone can create an account.",
                disabled: locked,
              },
              {
                value: "review",
                label: "Needs approval",
                icon: <UserCheck />,
                description: "New accounts need an admin’s approval.",
                disabled: locked,
              },
              {
                value: "disabled",
                label: "Closed",
                icon: <Lock />,
                description: "Only admins can add people.",
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
