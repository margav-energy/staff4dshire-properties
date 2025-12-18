'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

type NotificationType = 'info' | 'warning' | 'success' | 'error'

interface Notification {
  id: string
  title: string
  message: string
  type: NotificationType
  timestamp: string
  isRead: boolean
}

export default function NotificationsPage() {
  const router = useRouter()
  const [notifications, setNotifications] = useState<Notification[]>([
    {
      id: '1',
      title: 'New Incident Reported',
      message: 'John Doe reported an incident at City Center Development',
      type: 'warning',
      timestamp: '2024-01-16T10:30:00',
      isRead: false,
    },
    {
      id: '2',
      title: 'Document Expiring Soon',
      message: 'Your CSCS card expires in 30 days',
      type: 'warning',
      timestamp: '2024-01-15T14:20:00',
      isRead: false,
    },
    {
      id: '3',
      title: 'Timesheet Approved',
      message: 'Your timesheet for week of Jan 8 has been approved',
      type: 'success',
      timestamp: '2024-01-14T09:15:00',
      isRead: true,
    },
  ])

  const markAsRead = (id: string) => {
    setNotifications(notifications.map(n => n.id === id ? { ...n, isRead: true } : n))
  }

  const markAllAsRead = () => {
    setNotifications(notifications.map(n => ({ ...n, isRead: true })))
  }

  const unreadCount = notifications.filter(n => !n.isRead).length

  const getTypeIcon = (type: NotificationType) => {
    switch (type) {
      case 'info':
        return 'ℹ️'
      case 'warning':
        return '⚠️'
      case 'success':
        return '✅'
      case 'error':
        return '❌'
    }
  }

  const getTypeColor = (type: NotificationType) => {
    switch (type) {
      case 'info':
        return 'bg-blue-50 border-blue-200'
      case 'warning':
        return 'bg-orange-50 border-orange-200'
      case 'success':
        return 'bg-green-50 border-green-200'
      case 'error':
        return 'bg-red-50 border-red-200'
    }
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
              <h1 className="text-xl font-bold">Notifications</h1>
              {unreadCount > 0 && (
                <span className="px-3 py-1 bg-white text-primary-700 rounded-full text-sm font-semibold">
                  {unreadCount} new
                </span>
              )}
            </div>
            {unreadCount > 0 && (
              <button
                onClick={markAllAsRead}
                className="px-4 py-2 bg-white text-primary-700 rounded-lg font-semibold hover:bg-gray-100"
              >
                Mark all as read
              </button>
            )}
          </div>
        </div>
      </nav>

      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {notifications.length === 0 ? (
          <div className="card text-center py-12">
            <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
            <p className="text-gray-600">No notifications</p>
          </div>
        ) : (
          <div className="space-y-4">
            {notifications.map((notification) => (
              <div
                key={notification.id}
                onClick={() => markAsRead(notification.id)}
                className={`card cursor-pointer transition-all ${
                  !notification.isRead ? getTypeColor(notification.type) : ''
                } ${!notification.isRead ? 'border-l-4' : ''}`}
              >
                <div className="flex items-start space-x-4">
                  <div className="text-2xl">{getTypeIcon(notification.type)}</div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between mb-1">
                      <h3 className={`font-semibold ${!notification.isRead ? 'text-gray-900' : 'text-gray-700'}`}>
                        {notification.title}
                      </h3>
                      {!notification.isRead && (
                        <div className="w-2 h-2 bg-primary-700 rounded-full"></div>
                      )}
                    </div>
                    <p className="text-sm text-gray-600 mb-2">{notification.message}</p>
                    <p className="text-xs text-gray-500">
                      {new Date(notification.timestamp).toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}



