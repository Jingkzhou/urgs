
import React, { useState, useEffect, useCallback } from 'react';
import { ChevronLeft, ChevronRight, Menu, Home, Layers, Zap, Users, PieChart, ShieldCheck } from 'lucide-react';
import {
  TitlePage,
  TableOfContentsPage,
  ChallengePage,
  VisionPage,
  ArchitecturePage,
  PillarsPage,
  OrchestrationPage,
  DashboardPage,
  ReleaseManagementPage,
  AssetPillarPage,
  LineagePage,
  AiPillarPage,
  ArkAssistantPage,
  AiWorkflowPage,
  RolesPage,
  ConclusionPage,
  AIExperiencePage,
  SQLParsingDetailPage,
  RAGArchitecturePage
} from './components/Slides';

const App: React.FC = () => {
  const [currentSlide, setCurrentSlide] = useState(0);

  const slides = [
    <TitlePage key="title" />,
    <TableOfContentsPage onNavigate={setCurrentSlide} />,
    <ChallengePage key="challenge" />,
    <ArchitecturePage key="arch" />,
    <VisionPage key="vision" onNavigate={setCurrentSlide} />,

    <ConclusionPage key="end" />
  ];

  const totalSlides = slides.length;

  const nextSlide = useCallback(() => {
    setCurrentSlide((prev) => (prev < totalSlides - 1 ? prev + 1 : prev));
  }, [totalSlides]);

  const prevSlide = useCallback(() => {
    setCurrentSlide((prev) => (prev > 0 ? prev - 1 : prev));
  }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight' || e.key === 'PageDown' || e.key === ' ') nextSlide();
      if (e.key === 'ArrowLeft' || e.key === 'PageUp') prevSlide();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [nextSlide, prevSlide]);

  const renderSlide = () => {
    return slides[currentSlide];
  };

  return (
    <div className="relative h-screen w-screen bg-[#f9fafb] text-slate-900 flex flex-col overflow-hidden">
      {/* Navigation Header */}


      {/* Main Content Area */}
      <main className="flex-1 relative overflow-hidden flex items-center justify-center p-4 sm:p-12 lg:p-24 pt-24">
        {/* Key currentSlide ensures the whole container re-triggers animation on change */}
        <div key={currentSlide} className="w-full max-w-7xl h-full flex items-center justify-center animate-slide-in">
          {renderSlide()}
        </div>
      </main>

      {/* Persistent Controls */}
      <div className="absolute bottom-10 left-1/2 -translate-x-1/2 flex gap-4 z-50">
        <button
          onClick={prevSlide}
          className={`p-3 rounded-full bg-white shadow-lg border border-slate-200 hover:bg-slate-50 transition-all ${currentSlide === 0 ? 'opacity-30 cursor-not-allowed' : ''}`}
          aria-label="Previous Slide"
        >
          <ChevronLeft className="w-6 h-6 text-slate-700" />
        </button>
        <button
          onClick={nextSlide}
          className={`p-3 rounded-full bg-white shadow-lg border border-slate-200 hover:bg-slate-50 transition-all ${currentSlide === totalSlides - 1 ? 'opacity-30 cursor-not-allowed' : ''}`}
          aria-label="Next Slide"
        >
          <ChevronRight className="w-6 h-6 text-slate-700" />
        </button>
      </div>

      <style>{`
        @keyframes slide-in {
          from { opacity: 0; transform: translateX(30px); }
          to { opacity: 1; transform: translateX(0); }
        }
        @keyframes fade-up {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes fade-right {
          from { opacity: 0; transform: translateX(-20px); }
          to { opacity: 1; transform: translateX(0); }
        }
        @keyframes scale-in {
          from { opacity: 0; transform: scale(0.95); }
          to { opacity: 1; transform: scale(1); }
        }
        @keyframes float {
          0% { transform: translateY(0px); }
          50% { transform: translateY(-10px); }
          100% { transform: translateY(0px); }
        }

        .animate-slide-in { animation: slide-in 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .anim-fade-up { opacity: 0; animation: fade-up 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .anim-fade-right { opacity: 0; animation: fade-right 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .anim-scale-in { opacity: 0; animation: scale-in 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        .animate-float { animation: float 4s ease-in-out infinite; }

        .delay-100 { animation-delay: 100ms; }
        .delay-200 { animation-delay: 200ms; }
        .delay-300 { animation-delay: 300ms; }
        .delay-400 { animation-delay: 400ms; }
        .delay-500 { animation-delay: 500ms; }
        .delay-700 { animation-delay: 700ms; }
        .delay-1000 { animation-delay: 1000ms; }
      `}</style>
    </div>
  );
};

export default App;
