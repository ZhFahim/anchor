"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { Mail, Lock, Loader2, AlertCircle, User } from "lucide-react";
import { useQuery } from "@tanstack/react-query";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useAuth, getRegistrationMode } from "@/features/auth";

export default function RegisterPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");
  const { register, isRegisterPending } = useAuth();

  const { data: registrationMode, isLoading: modeLoading } = useQuery({
    queryKey: ["registration-mode"],
    queryFn: getRegistrationMode,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    if (password !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    if (password.length < 8) {
      setError("Password must be at least 8 characters");
      return;
    }

    if (!name.trim()) {
      setError("Please enter your name");
      return;
    }

    register({ email, password, name: name.trim() });
  };

  return (
    <Card className="border-0 shadow-xl bg-card/80 backdrop-blur-sm overflow-hidden">
      <div
        className="transition-[max-height] duration-500 ease-out"
        style={{ maxHeight: modeLoading ? 240 : 700 }}
      >
        {modeLoading ? (
          <CardContent className="py-16">
            <div className="flex items-center justify-center py-8">
              <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            </div>
          </CardContent>
        ) : registrationMode?.mode === "disabled" ? (
          <div className="animate-card-entrance">
            <CardHeader className="space-y-4 text-center pb-2">
              <div className="mx-auto flex items-center justify-center">
                <Image
                  src="/icons/anchor_icon.png"
                  alt="Anchor"
                  width={64}
                  height={64}
                />
              </div>
              <div className="space-y-1">
                <CardTitle className="text-3xl font-serif">Registration Disabled</CardTitle>
                <CardDescription className="text-muted-foreground">
                  User sign up is currently disabled
                </CardDescription>
              </div>
            </CardHeader>
            <CardContent className="pt-4">
              <div className="flex items-start gap-3 p-4 border rounded-lg bg-muted/50">
                <AlertCircle className="h-5 w-5 mt-0.5 text-muted-foreground" />
                <div className="flex-1 text-sm">
                  <p className="text-muted-foreground">
                    New account registration is not available at this time. Please contact an administrator to create an account.
                  </p>
                </div>
              </div>
              <div className="mt-6 text-center">
                <p className="text-sm text-muted-foreground">
                  Already have an account?{" "}
                  <Link
                    href="/login"
                    className="font-medium text-accent hover:text-accent/80 transition-colors"
                  >
                    Sign in
                  </Link>
                </p>
              </div>
            </CardContent>
          </div>
        ) : (
          <div className="animate-card-entrance">
            <CardHeader className="space-y-4 text-center pb-2">
              <div className="mx-auto flex items-center justify-center">
                <Image
                  src="/icons/anchor_icon.png"
                  alt="Anchor"
                  width={64}
                  height={64}
                />
              </div>
              <div className="space-y-1">
                <CardTitle className="text-3xl font-serif">Create Account</CardTitle>
                <CardDescription className="text-muted-foreground">
                  {registrationMode?.mode === "review"
                    ? "Register and wait for approval"
                    : "Start capturing your thoughts"}
                </CardDescription>
              </div>
            </CardHeader>
            <CardContent className="pt-4">
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Name</Label>
                  <div className="relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="name"
                      type="text"
                      placeholder="Your name"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      className="pl-10 h-12 bg-background/50"
                      required
                      maxLength={100}
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="email"
                      type="email"
                      placeholder="you@example.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="pl-10 h-12 bg-background/50"
                      required
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="password">Password</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="password"
                      type="password"
                      placeholder="••••••••"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="pl-10 h-12 bg-background/50"
                      required
                      minLength={8}
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="confirmPassword">Confirm Password</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="confirmPassword"
                      type="password"
                      placeholder="••••••••"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      className="pl-10 h-12 bg-background/50"
                      required
                      minLength={8}
                    />
                  </div>
                </div>
                {error && (
                  <p className="text-sm text-destructive text-center">{error}</p>
                )}
                <Button
                  type="submit"
                  className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-medium"
                  disabled={isRegisterPending}
                >
                  {isRegisterPending ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Creating account...
                    </>
                  ) : (
                    "Create Account"
                  )}
                </Button>
              </form>
              <div className="mt-6 text-center">
                <p className="text-sm text-muted-foreground">
                  Already have an account?{" "}
                  <Link
                    href="/login"
                    className="font-medium text-accent hover:text-accent/80 transition-colors"
                  >
                    Sign in
                  </Link>
                </p>
              </div>
            </CardContent>
          </div>
        )}
      </div>
    </Card>
  );
}

