import { Router } from 'express';

const router = Router();

// In-memory + persistent fallback notification storage
let notifications = [
  {
    id: 'notif_01',
    title: '⏰ Dinner Mess-Off Cutoff at 05:00 PM',
    body: 'Students planning to dine outside must apply for mess-off before 05:00 PM to receive meal rebate credit.',
    category: 'messoff',
    target: 'All Residents (112 Students)',
    sender: 'Hostel H4 Mess Manager',
    createdAt: new Date().toISOString(),
    read: false,
    deliveredCount: 112
  },
  {
    id: 'notif_02',
    title: '🍲 Special Sunday Feast Announced',
    body: 'Special Paneer Butter Masala, Pulao, Gulab Jamun served this Sunday for Dinner.',
    category: 'menu',
    target: 'Hostel No. 4 Central Dining',
    sender: 'Hostel H4 Mess Manager',
    createdAt: new Date(Date.now() - 3600000 * 24).toISOString(),
    read: true,
    deliveredCount: 112
  },
  {
    id: 'notif_03',
    title: '⚡ QR Attendance Counter Operational',
    body: 'Counter scanners are active from 08:00 PM to 10:00 PM for dinner QR verification.',
    category: 'alert',
    target: 'Active Diners',
    sender: 'Hostel H4 Mess Manager',
    createdAt: new Date(Date.now() - 3600000 * 48).toISOString(),
    read: true,
    deliveredCount: 98
  }
];

// GET /notifications - Get all live notifications
router.get('/', (req, res) => {
  res.json({ success: true, count: notifications.length, notifications });
});

// POST /notifications - Broadcast new notification
router.post('/', (req, res) => {
  const { title, body, category, target } = req.body;
  if (!title || !body) {
    return res.status(400).json({ error: 'Title and body are required' });
  }

  const newNotif = {
    id: `notif_${Date.now()}`,
    title: title.trim(),
    body: body.trim(),
    category: category || 'alert',
    target: target || 'All Residents',
    sender: 'Hostel H4 Mess Manager',
    createdAt: new Date().toISOString(),
    read: false,
    deliveredCount: 112
  };

  notifications = [newNotif, ...notifications];
  console.log(`[BROADCAST] Dispatched notification: ${newNotif.title}`);
  res.json({ success: true, notification: newNotif });
});

export default router;
