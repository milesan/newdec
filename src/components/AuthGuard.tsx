import { ReactNode } from 'react';
import { Auth } from './Auth';
import { useSession } from '../hooks/useSession';

interface AuthGuardProps {
  children: ReactNode;
}

export function AuthGuard({ children }: AuthGuardProps) {
  const session = useSession();

  if (!session) {
    return (
      <div className="min-h-screen bg-stone-50 py-12">
        <div className="container mx-auto px-4">
          <Auth />
        </div>
      </div>
    );
  }

  return <>{children}</>;
}