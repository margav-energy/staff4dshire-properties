'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

type DocumentType = 'all' | 'cscs' | 'health-safety' | 'insurance' | 'cpp' | 'rams' | 'driver-license' | 'compliance' | 'accreditation' | 'other'

interface Document {
  id: string
  name: string
  type: DocumentType
  uploadDate: string
  expiryDate?: string
  isVerified: boolean
  isExpired: boolean
  isExpiringSoon: boolean
}

export default function DocumentsPage() {
  const router = useRouter()
  const [selectedFilter, setSelectedFilter] = useState<DocumentType>('all')
  const [showUploadDialog, setShowUploadDialog] = useState(false)

  // Mock data
  const documents: Document[] = [
    {
      id: '1',
      name: 'CSCS Card',
      type: 'cscs',
      uploadDate: '2024-01-01',
      expiryDate: '2025-01-01',
      isVerified: true,
      isExpired: false,
      isExpiringSoon: false,
    },
    {
      id: '2',
      name: 'Health & Safety Certificate',
      type: 'health-safety',
      uploadDate: '2024-01-15',
      expiryDate: '2024-03-15',
      isVerified: true,
      isExpired: false,
      isExpiringSoon: true,
    },
  ]

  const filteredDocuments = selectedFilter === 'all' 
    ? documents 
    : documents.filter(doc => doc.type === selectedFilter)

  const expiredDocs = documents.filter(doc => doc.isExpired)
  const expiringDocs = documents.filter(doc => doc.isExpiringSoon && !doc.isExpired)

  const documentTypes: { value: DocumentType; label: string }[] = [
    { value: 'all', label: 'All' },
    { value: 'cscs', label: 'CSCS' },
    { value: 'health-safety', label: 'H&S' },
    { value: 'insurance', label: 'Insurance' },
    { value: 'cpp', label: 'CPP' },
    { value: 'rams', label: 'RAMS' },
    { value: 'driver-license', label: 'Driver License' },
    { value: 'compliance', label: 'Compliance' },
    { value: 'accreditation', label: 'Accreditation' },
    { value: 'other', label: 'Other' },
  ]

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
              <h1 className="text-xl font-bold">Document Hub</h1>
            </div>
            <button
              onClick={() => setShowUploadDialog(true)}
              className="p-2 hover:bg-primary-800 rounded-lg"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
            </button>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Alerts */}
        {(expiredDocs.length > 0 || expiringDocs.length > 0) && (
          <div className={`card mb-6 ${
            expiredDocs.length > 0 ? 'bg-red-50 border-red-200' : 'bg-orange-50 border-orange-200'
          }`}>
            <div className="flex items-center">
              <svg className={`w-6 h-6 mr-3 ${
                expiredDocs.length > 0 ? 'text-red-600' : 'text-orange-600'
              }`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
              <div className="flex-1">
                <p className={`font-semibold ${
                  expiredDocs.length > 0 ? 'text-red-800' : 'text-orange-800'
                }`}>
                  {expiredDocs.length > 0
                    ? `${expiredDocs.length} Document(s) Expired`
                    : `${expiringDocs.length} Document(s) Expiring Soon`}
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Filter Chips */}
        <div className="mb-6 overflow-x-auto">
          <div className="flex space-x-2">
            {documentTypes.map((type) => (
              <button
                key={type.value}
                onClick={() => setSelectedFilter(type.value)}
                className={`px-4 py-2 rounded-full font-medium whitespace-nowrap transition-colors ${
                  selectedFilter === type.value
                    ? 'bg-primary-700 text-white'
                    : 'bg-white text-gray-700 hover:bg-gray-100'
                }`}
              >
                {type.label}
              </button>
            ))}
          </div>
        </div>

        {/* Documents List */}
        {filteredDocuments.length === 0 ? (
          <div className="card text-center py-12">
            <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <p className="text-gray-600">No documents found</p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredDocuments.map((doc) => (
              <div
                key={doc.id}
                className={`card ${
                  doc.isExpired
                    ? 'bg-red-50 border-red-200'
                    : doc.isExpiringSoon
                    ? 'bg-orange-50 border-orange-200'
                    : ''
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-4">
                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                      doc.isExpired
                        ? 'bg-red-100'
                        : doc.isExpiringSoon
                        ? 'bg-orange-100'
                        : 'bg-primary-100'
                    }`}>
                      <svg className={`w-6 h-6 ${
                        doc.isExpired
                          ? 'text-red-600'
                          : doc.isExpiringSoon
                          ? 'text-orange-600'
                          : 'text-primary-700'
                      }`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900">{doc.name}</h3>
                      <p className="text-sm text-gray-600 mt-1 capitalize">{doc.type.replace('-', ' ')}</p>
                      {doc.expiryDate && (
                        <p className={`text-xs mt-1 ${
                          doc.isExpired
                            ? 'text-red-600 font-semibold'
                            : doc.isExpiringSoon
                            ? 'text-orange-600 font-semibold'
                            : 'text-gray-500'
                        }`}>
                          Expires: {new Date(doc.expiryDate).toLocaleDateString()}
                        </p>
                      )}
                      {doc.isVerified && (
                        <span className="inline-flex items-center mt-1 text-xs text-green-600">
                          <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                          </svg>
                          Verified
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <button className="p-2 hover:bg-gray-100 rounded-lg">
                      <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                      </svg>
                    </button>
                    <button className="p-2 hover:bg-gray-100 rounded-lg">
                      <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Upload Dialog */}
      {showUploadDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full mx-4">
            <h2 className="text-xl font-bold mb-4">Upload Document</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Document Type
                </label>
                <select className="input-field">
                  {documentTypes.slice(1).map((type) => (
                    <option key={type.value} value={type.value}>
                      {type.label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Expiry Date (Optional)
                </label>
                <input type="date" className="input-field" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  File
                </label>
                <input type="file" className="input-field" />
              </div>
              <div className="flex space-x-4">
                <button
                  onClick={() => setShowUploadDialog(false)}
                  className="btn-outline flex-1"
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    setShowUploadDialog(false)
                    alert('Document uploaded successfully')
                  }}
                  className="btn-primary flex-1"
                >
                  Upload
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}



