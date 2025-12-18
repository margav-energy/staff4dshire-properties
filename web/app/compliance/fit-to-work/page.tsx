'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function FitToWorkPage() {
  const router = useRouter()
  const [isFit, setIsFit] = useState(true)
  const [notes, setNotes] = useState('')

  const handleSubmit = async () => {
    // Submit declaration
    alert(isFit ? 'Fit to work declaration submitted' : 'Not fit to work declaration submitted')
    router.back()
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-primary-700 text-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <button onClick={() => router.back()} className="p-2 hover:bg-primary-800 rounded-lg">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </button>
              <h1 className="text-xl font-bold">Fit to Work Declaration</h1>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Info Card */}
        <div className="card bg-primary-50 border-primary-200 mb-6">
          <div className="flex items-start">
            <svg className="w-6 h-6 text-primary-700 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p className="text-primary-800">
              Please complete this declaration before starting work
            </p>
          </div>
        </div>

        {/* Declaration Title */}
        <h2 className="text-3xl font-bold text-center mb-8">
          Are you fit to work today?
        </h2>

        {/* Fit/Not Fit Toggle */}
        <div className="grid grid-cols-2 gap-4 mb-8">
          <button
            onClick={() => setIsFit(true)}
            className={`card p-6 text-center transition-colors ${
              isFit ? 'bg-primary-50 border-2 border-primary-700' : ''
            }`}
          >
            <svg className={`w-12 h-12 mx-auto mb-3 ${
              isFit ? 'text-primary-700' : 'text-gray-400'
            }`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p className={`font-semibold ${
              isFit ? 'text-primary-700' : 'text-gray-600'
            }`}>
              Fit to Work
            </p>
          </button>

          <button
            onClick={() => setIsFit(false)}
            className={`card p-6 text-center transition-colors ${
              !isFit ? 'bg-red-50 border-2 border-red-600' : ''
            }`}
          >
            <svg className={`w-12 h-12 mx-auto mb-3 ${
              !isFit ? 'text-red-600' : 'text-gray-400'
            }`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p className={`font-semibold ${
              !isFit ? 'text-red-600' : 'text-gray-600'
            }`}>
              Not Fit
            </p>
          </button>
        </div>

        {/* Notes Field */}
        <div className="mb-8">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Notes (Optional)
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            className="input-field"
            rows={4}
            placeholder="Add any additional information..."
          />
        </div>

        {/* Submit Button */}
        <button
          onClick={handleSubmit}
          className={`w-full py-4 rounded-xl font-semibold text-white transition-colors ${
            isFit
              ? 'bg-primary-700 hover:bg-primary-800'
              : 'bg-red-600 hover:bg-red-700'
          }`}
        >
          {isFit ? 'Submit Declaration' : 'Report Not Fit'}
        </button>
      </div>
    </div>
  )
}



