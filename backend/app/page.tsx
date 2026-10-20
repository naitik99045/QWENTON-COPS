import Link from "next/link";
import { ShieldCheck, Zap, ArrowRight, Activity, Terminal } from "lucide-react";

export default function HomePage() {
  return (
    <main className="min-h-screen bg-slate-900 text-white flex flex-col justify-center items-center p-6">
      <div className="max-w-xl w-full text-center space-y-6">
        <div className="inline-flex items-center space-y-0 space-x-2 bg-blue-500/10 border border-blue-500/20 px-3 py-1.5 rounded-full text-blue-400 text-xs font-semibold">
          <Zap className="w-3.5 h-3.5 text-blue-400" />
          <span>Qwenton CommerceOps Engine</span>
        </div>

        <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight">
          Vercel Backend Service
        </h1>
        <p className="text-slate-400 text-sm sm:text-base leading-relaxed">
          Operational payment and webhook gateway powering the Qwenton CommerceOps dual Android apps. Connected to FamGateway UPI and Cloud Firestore.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-4 text-left">
          <div className="bg-slate-800/80 border border-slate-700/60 p-4 rounded-xl">
            <div className="flex items-center space-x-2 text-xs font-mono text-emerald-400 mb-2">
              <Activity className="w-4 h-4" />
              <span>POST /api/webhook/famgateway</span>
            </div>
            <p className="text-xs text-slate-400">
              HMAC-SHA256 verified webhook listener updating Firestore in real-time.
            </p>
          </div>

          <div className="bg-slate-800/80 border border-slate-700/60 p-4 rounded-xl">
            <div className="flex items-center space-x-2 text-xs font-mono text-blue-400 mb-2">
              <Terminal className="w-4 h-4" />
              <span>POST /api/famgateway/create-order</span>
            </div>
            <p className="text-xs text-slate-400">
              Generates UPI Intent links & FamGateway checkout sessions for Android user app.
            </p>
          </div>
        </div>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-4">
          <Link
            href="/api/health"
            className="w-full sm:w-auto inline-flex items-center justify-center space-x-2 bg-blue-600 hover:bg-blue-500 text-white text-sm font-semibold px-5 py-2.5 rounded-lg transition"
          >
            <span>Check Health Status</span>
            <ArrowRight className="w-4 h-4" />
          </Link>
          <Link
            href="/p/chikankari-pink"
            className="w-full sm:w-auto inline-flex items-center justify-center space-x-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-sm font-semibold px-5 py-2.5 rounded-lg border border-slate-700 transition"
          >
            <span>View Demo Storefront</span>
          </Link>
        </div>

        <div className="pt-8 border-t border-slate-800 text-xs text-slate-500 flex items-center justify-center space-x-2">
          <ShieldCheck className="w-4 h-4 text-emerald-500" />
          <span>Production Domain: qwen.qwenton.shop</span>
        </div>
      </div>
    </main>
  );
}
