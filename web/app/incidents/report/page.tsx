'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

type Severity = 'low' | 'medium' | 'high' | 'critical'

export default function ReportIncidentPage() {
  const router = useRouter()
  const [description, setDescription] = useState('')
  const [severity, setSeverity] = useState<Severity>('medium')
  const [selectedImage, setSelectedImage] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onloadend = () => {
        setSelectedImage(reader.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleSubmit = async () => {
    if (!description.trim() || description.length < 10) {
      alert('Please enter a description (at least 10 characters)')
      return
    }

    if (!selectedImage) {
      alert('Please add a photo of the incident')
      return
    }

    setIsSubmitting(true)
    await new Promise(resolve => setTimeout(resolve, 1500))
    setIsSubmitting(false)
    alert('Incident reported successfully')
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
              <h1 className="text-xl font-bold">Report Incident</h1>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Instructions */}
        <div className="card bg-orange-50 border-orange-200 mb-6">
          <div className="flex items-start">
            <svg className="w-6 h-6 text-orange-600 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p className="text-orange-800">
              Please provide a clear description and photo of the incident.
            </p>
          </div>
        </div>

        {/* Incident Photo */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Incident Photo *
          </label>
          <div
            onClick={() => document.getElementById('image-upload')?.click()}
            className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center cursor-pointer hover:border-primary-700 transition-colors"
          >
            {selectedImage ? (
              <img src={selectedImage} alt="Incident" className="max-h-64 mx-auto rounded-lg" />
            ) : (
              <>
                <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <p className="text-gray-600">Tap to add photo</p>
              </>
            )}
          </div>
          <input
            id="image-upload"
            type="file"
            accept="image/*"
            onChange={handleImageChange}
            className="hidden"
          />
          {selectedImage && (
            <button
              onClick={() => {
                setSelectedImage(null)
                document.getElementById('image-upload')!.value = ''
              }}
              className="mt-2 text-sm text-primary-700 hover:text-primary-800"
            >
              Change Photo
            </button>
          )}
        </div>

        {/* Severity Selection */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Severity
          </label>
          <div className="grid grid-cols-4 gap-2">
            {(['low', 'medium', 'high', 'critical'] as Severity[]).map((sev) => (
              <button
                key={sev}
                onClick={() => setSeverity(sev)}
                className={`py-3 rounded-xl font-medium transition-colors ${
                  severity === sev
                    ? sev === 'low'
                      ? 'bg-green-600 text-white'
                      : sev === 'medium'
                      ? 'bg-yellow-600 text-white'
                      : sev === 'high'
                      ? 'bg-orange-600 text-white'
                      : 'bg-red-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {sev.charAt(0).toUpperCase() + sev.slice(1)}
              </button>
            ))}
          </div>
        </div>

        {/* Description */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Description *
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="input-field"
            rows={6}
            placeholder="Describe what happened, when, where, and any relevant details..."
            required
          />
          <p className="text-xs text-gray-500 mt-1">
            Minimum 10 characters ({description.length} / 10)
          </p>
        </div>

        {/* Submit Button */}
        <button
          onClick={handleSubmit}
          disabled={isSubmitting || description.length < 10 || !selectedImage}
          className="w-full py-4 bg-red-600 text-white rounded-xl font-semibold hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {isSubmitting ? 'Reporting...' : 'Report Incident'}
        </button>
      </div>
    </div>
  )
}



