import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Terminal } from 'lucide-react';
import { useNavigate, useLocation } from 'react-router-dom';
import { PasswordCheckModal } from '../PasswordCheckModal';
import { WhitelistWelcomeModal } from '../WhitelistWelcomeModal';

interface Props {
  onComplete: () => void;
}

const ASCII_ART = `████████╗██╗  ██╗███████╗     ██████╗  █████╗ ██████╗ ██████╗ ███████╗███╗   ██╗
╚══██╔══╝██║  ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║
   ██║   ███████║█████╗      ██║  ███╗███████║██████╔╝██║  ██║█████╗  ██╔██╗ ██║
   ██║   ██╔══██║██╔══╝      ██║   ██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚██╗██║
   ██║   ██║  ██║███████╗    ╚██████╔╝██║  ██║██║  ██║██████╔╝███████╗██║ ╚████║
   ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝`;

const MOBILE_ASCII_ART = ` `;

export function Retro2Intro({ onComplete }: Props) {
  const [asciiLines, setAsciiLines] = useState<string[]>([]);
  const [currentLine, setCurrentLine] = useState(0);
  const [currentChar, setCurrentChar] = useState(0);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [showWelcomeModal, setShowWelcomeModal] = useState(false);
  const isMobile = window.innerWidth < 768;
  const navigate = useNavigate();
  const location = useLocation();
  const isFromLogin = location.pathname === '/retro2';

  useEffect(() => {
    // Skip animation on mobile when coming from login
    if (isMobile && isFromLogin) {
      onComplete();
      return;
    }

    setAsciiLines((isMobile ? MOBILE_ASCII_ART : ASCII_ART).split('\n'));
  }, [isMobile, onComplete, isFromLogin]);

  useEffect(() => {
    if (asciiLines.length === 0 || currentLine >= asciiLines.length) return;

    const line = asciiLines[currentLine];
    if (currentChar >= line.length) {
      setTimeout(() => {
        setCurrentLine(prev => prev + 1);
        setCurrentChar(0);
      }, 100);
      return;
    }

    const timer = setTimeout(() => {
      setCurrentChar(prev => prev + 1);
    }, 7);

    return () => clearTimeout(timer);
  }, [asciiLines, currentLine, currentChar]);

  useEffect(() => {
    if (currentLine >= asciiLines.length && asciiLines.length > 0) {
      setShowPasswordModal(true);
    }
  }, [currentLine, asciiLines.length]);

  const handlePasswordSuccess = () => {
    setShowPasswordModal(false);
    setShowWelcomeModal(true);
  };

  const handlePasswordClose = () => {
    setShowPasswordModal(false);
    onComplete();
  };

  const handleWelcomeClose = () => {
    setShowWelcomeModal(false);
    navigate('/');
  };

  return (
    <div className="min-h-screen bg-black flex items-center justify-center p-4 overflow-hidden">
      <pre 
        className="text-[#FFBF00] whitespace-pre font-mono text-sm md:text-base lg:text-lg overflow-x-auto max-w-full text-center"
        style={{ 
          maxHeight: '90vh',
          overflowY: 'auto',
          scrollbarWidth: 'none',
          msOverflowStyle: 'none',
          transform: isMobile ? 'scale(0.8)' : 'none'
        }}
      >
        {asciiLines.slice(0, currentLine).map((line, i) => (
          <div key={i} className="min-w-max">
            {i === currentLine - 1 ? line.slice(0, currentChar) : line}
          </div>
        ))}
      </pre>

      <PasswordCheckModal 
        isOpen={showPasswordModal}
        onClose={handlePasswordClose}
        onSuccess={handlePasswordSuccess}
      />

      <WhitelistWelcomeModal
        isOpen={showWelcomeModal}
        onClose={handleWelcomeClose}
      />

      {/* Invisible button in top-right corner */}
      <div
        onClick={() => navigate('/retro2')}
        className="fixed top-0 right-0 w-[30px] h-[30px] cursor-default z-50"
        style={{ opacity: 0 }}
      />
    </div>
  );
}