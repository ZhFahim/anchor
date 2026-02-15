"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useSearchParams } from "next/navigation";
import { Mail, Lock, Loader2, LogIn } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useAuth, useOidcConfig, useOidcLogin, useOidcCallback } from "@/features/auth";
import { getSafeRedirectUrl } from "@/features/auth/utils/redirect";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const searchParams = useSearchParams();
  const { login, isLoginPending } = useAuth();
  const { data: oidcConfig, isLoading: oidcConfigLoading, error: oidcConfigError } = useOidcConfig();
  const { initiate: initiateOidcLogin } = useOidcLogin();
  const { isProcessing: isOidcCallbackProcessing } = useOidcCallback();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    login({ email, password });
  };

  const handleOidcLogin = () => {
    const returnTo = searchParams.get("returnTo");
    const redirectUrl = getSafeRedirectUrl(returnTo || "/");
    initiateOidcLogin(redirectUrl !== "/" ? redirectUrl : undefined);
  };

  const showLocalLogin = !oidcConfig?.disableInternalAuth;
  const isLoading = oidcConfigLoading || isOidcCallbackProcessing;

  return (
    <Card className="border-0 shadow-xl bg-card/80 backdrop-blur-sm overflow-hidden">
      <div
        className="transition-[max-height] duration-500 ease-out"
        style={{ maxHeight: isLoading ? 240 : 700 }}
      >
        {isLoading ? (
          <CardContent className="py-16">
            <div className="flex items-center justify-center py-8">
              <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            </div>
          </CardContent>
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
                <CardTitle className="text-3xl font-serif">Welcome Back</CardTitle>
                <CardDescription className="text-muted-foreground">
                  Sign in to continue to Anchor
                </CardDescription>
              </div>
            </CardHeader>
            <CardContent className="pt-4">
              {oidcConfigError && (
                <p className="text-sm text-destructive mb-4" role="alert">
                  Could not load sign-in options. Please try again.
                </p>
              )}
              {/* OIDC Login Button */}
              {oidcConfig?.enabled && (
                <div className="space-y-4">
                  <Button
                    type="button"
                    onClick={handleOidcLogin}
                    className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-medium"
                  >
                    <LogIn className="mr-2 h-4 w-4" />
                    Login with {oidcConfig.providerName}
                  </Button>
                  {showLocalLogin && (
                    <div className="relative">
                      <div className="absolute inset-0 flex items-center">
                        <span className="w-full border-t" />
                      </div>
                      <div className="relative flex justify-center text-xs uppercase">
                        <span className="bg-card px-2 text-muted-foreground">
                          Or continue with
                        </span>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* Local Login Form */}
              {showLocalLogin && (
                <form onSubmit={handleSubmit} className="space-y-4">
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
                      />
                    </div>
                  </div>
                  <Button
                    type="submit"
                    className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-medium"
                    disabled={isLoginPending}
                  >
                    {isLoginPending ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        Signing in...
                      </>
                    ) : (
                      "Sign In"
                    )}
                  </Button>
                </form>
              )}

              {/* Registration Link */}
              {showLocalLogin && (
                <div className="mt-6 text-center">
                  <p className="text-sm text-muted-foreground">
                    Don&apos;t have an account?{" "}
                    <Link
                      href="/register"
                      className="font-medium text-accent hover:text-accent/80 transition-colors"
                    >
                      Create one
                    </Link>
                  </p>
                </div>
              )}
            </CardContent>
          </div>
        )}
      </div>
    </Card>
  );
}

