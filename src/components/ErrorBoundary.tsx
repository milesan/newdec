import React, { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Uncaught error:', error, errorInfo);
  }

  public render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-stone-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg shadow-lg p-6 max-w-md w-full">
            <h2 className="text-xl font-semibold text-stone-900 mb-4">Something went wrong</h2>
            <p className="text-stone-600 mb-4">
              We're having trouble connecting to our servers. Please try:
            </p>
            <ul className="list-disc list-inside text-stone-600 mb-6 space-y-2">
              <li>Refreshing the page</li>
              <li>Checking your internet connection</li>
              <li>Trying again in a few minutes</li>
            </ul>
            <button
              onClick={() => window.location.reload()}
              className="w-full bg-emerald-900 text-white py-2 px-4 rounded-lg hover:bg-emerald-800 transition-colors"
            >
              Refresh Page
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}