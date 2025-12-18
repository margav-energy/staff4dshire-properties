'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'

export default function SignInOutPage() {
  const router = useRouter()
  const [isSignedIn, setIsSignedIn] = useState(false)
  const [signInTime, setSignInTime] = useState<Date | null>(null)
  const [selectedProject, setSelectedProject] = useState<string | null>(null)
  const [currentTime, setCurrentTime] = useState(new Date())

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date())
    }, 1000)
    return () => clearInterval(timer)
  }, [])

  const handleSignIn = async () => {
    if (!selectedProject) {
      alert('Please select a project first')
      return
    }
    
    // Get current location
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          console.log('Location:', position.coords.latitude, position.coords.longitude)
        },
        (error) => {
          console.error('Location error:', error)
        }
      )
    }
    
    setIsSignedIn(true)
    setSignInTime(new Date())
  }

  const handleSignOut = () => {
    setIsSignedIn(false)
    setSignInTime(null)
    setSelectedProject(null)
  }

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', { hour12: false })
  }

  const formatDateTime = (date: Date) => {
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric', 
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    })
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-primary-700 text-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <h1 className="text-xl font-bold">Sign In/Out</h1>
            <button
              onClick={() => router.back()}
              className="p-2 hover:bg-primary-800 rounded-lg"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
      </nav>

      <div className="max-w-2xl mx-auto px-4 py-8">
        {/* Status Card */}
        <div className="card mb-6">
          <div className="text-center">
            <div className={`w-20 h-20 mx-auto mb-4 rounded-full flex items-center justify-center ${
              isSignedIn ? 'bg-green-100' : 'bg-gray-100'
            }`}>
              {isSignedIn ? (
                <svg className="w-10 h-10 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              ) : (
                <svg className="w-10 h-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 12H6" />
                </svg>
              )}
            </div>
            <h2 className={`text-2xl font-bold mb-2 ${
              isSignedIn ? 'text-green-600' : 'text-gray-600'
            }`}>
              {isSignedIn ? 'Signed In' : 'Not Signed In'}
            </h2>
            {signInTime && (
              <p className="text-gray-600">
                Since {formatDateTime(signInTime)}
              </p>
            )}
          </div>
        </div>

        {/* Project Selection */}
        <div className="card mb-6">
          <div
            onClick={() => {
              // In a real app, this would open a project selection modal/page
              const project = prompt('Select project (this is a demo):', 'City Center Development')
              if (project) {
                setSelectedProject(project)
              }
            }}
            className="flex items-center cursor-pointer hover:bg-gray-50 p-4 rounded-xl transition-colors"
          >
            <svg className="w-6 h-6 text-primary-700 mr-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <div className="flex-1">
              <p className="text-sm text-gray-600">Project</p>
              <p className={`font-medium ${selectedProject ? 'text-gray-900' : 'text-gray-400'}`}>
                {selectedProject || 'Select Project'}
              </p>
            </div>
            <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </div>
        </div>

        {/* Location Status */}
        <div className="card mb-6">
          <div className="flex items-start">
            <svg className="w-6 h-6 text-green-600 mr-4 mt-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <div className="flex-1">
              <p className="font-medium text-gray-900 mb-1">Location</p>
              <p className="text-sm text-gray-600">
                {isSignedIn ? 'Location captured on sign-in' : 'Location will be captured on sign-in'}
              </p>
            </div>
          </div>
        </div>

        {/* Fit to Work Declaration */}
        {!isSignedIn && (
          <div className="card mb-6 bg-primary-50 border-primary-200">
            <div className="flex items-start">
              <svg className="w-6 h-6 text-primary-700 mr-3 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <div className="flex-1">
                <p className="font-medium text-primary-800 mb-1">Fit to Work Declaration</p>
                <p className="text-sm text-primary-700 mb-3">
                  Please complete your fit-to-work declaration before signing in
                </p>
                <button
                  onClick={() => router.push('/compliance/fit-to-work')}
                  className="text-sm text-primary-700 font-semibold hover:text-primary-800"
                >
                  Complete Declaration →
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Sign In/Out Button */}
        {!isSignedIn ? (
          <button
            onClick={handleSignIn}
            className="btn-primary w-full py-4 text-lg mb-6"
          >
            <div className="flex items-center justify-center">
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
              </svg>
              Sign In
            </div>
          </button>
        ) : (
          <button
            onClick={handleSignOut}
            className="btn-outline border-red-600 text-red-600 hover:bg-red-50 w-full py-4 text-lg mb-6"
          >
            <div className="flex items-center justify-center">
              <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
              </svg>
              Sign Out
            </div>
          </button>
        )}

        {/* Current Time */}
        <div className="card bg-gray-100">
          <div className="flex items-center justify-center">
            <svg className="w-6 h-6 text-primary-700 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span className="text-3xl font-bold text-primary-700">
              {formatTime(currentTime)}
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

