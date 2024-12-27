import React from 'react';
import { useSession } from '../hooks/useSession';

export function AdminButton() {
  const session = useSession();

  // Only show admin button for andre@thegarden.pt
  if (!session?.user?.email || session.user.email !== 'andre@thegarden.pt') {
    return null;
  }

  return null; // We don't need this component anymore since admin is in the nav
}