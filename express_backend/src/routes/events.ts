import { Router } from 'express';

const router = Router();

let events = [
  {
    id: 'evt_1',
    title: 'Mid-Semester Examinations (6th Semester)',
    type: 'Exam',
    startDate: '2026-09-02',
    endDate: '2026-09-08',
    impactLevel: 'Medium',
    expectedMessOffs: '35% Higher Attendance in Mess (Night Snacks Active)',
    description: '6th Semester university theory examinations across CSE, Civil, ECE, EE, and ME.',
    advisoryForStudents: 'Extended dining hours will be active. Students staying in hostel need not apply for mess-off.'
  },
  {
    id: 'evt_2',
    title: 'Diwali & Chhath Puja Semester Break',
    type: 'Holiday',
    startDate: '2026-10-28',
    endDate: '2026-11-06',
    impactLevel: 'High',
    expectedMessOffs: '85% Mess-Off Turnout (Estimated ~95 residents absent)',
    description: 'Official institute holiday for festival break. Hostel mess runs on minimal staff.',
    advisoryForStudents: 'Residents travelling home must submit Mess-Off requests before Oct 27 (8 PM) to get full fee waiver.'
  },
  {
    id: 'evt_3',
    title: 'Annual Technical Fest (TechKriti 2026)',
    type: 'College Fest',
    startDate: '2026-09-20',
    endDate: '2026-09-22',
    impactLevel: 'Medium',
    expectedMessOffs: 'Feast Menu Active (Special Dinner on Day 3)',
    description: 'Inter-college technical and cultural fest with guest participants from other engineering colleges.',
    advisoryForStudents: 'Special Sunday Feast menu will be served. Day scholars and guests can purchase coupons.'
  }
];

// GET /events
router.get('/', (req, res) => {
  res.json({ success: true, count: events.length, events });
});

// POST /events
router.post('/', (req, res) => {
  const { title, type, startDate, endDate, impactLevel, expectedMessOffs, description, advisoryForStudents } = req.body;
  if (!title || !startDate) {
    return res.status(400).json({ error: 'Title and startDate are required' });
  }

  const newEvt = {
    id: req.body.id || `evt_${Date.now()}`,
    title: title.trim(),
    type: type || 'Holiday',
    startDate,
    endDate: endDate || startDate,
    impactLevel: impactLevel || 'Medium',
    expectedMessOffs: expectedMessOffs || '',
    description: description || '',
    advisoryForStudents: advisoryForStudents || ''
  };

  const existingIdx = events.findIndex(e => e.id === newEvt.id);
  if (existingIdx >= 0) {
    events[existingIdx] = newEvt;
  } else {
    events = [newEvt, ...events];
  }

  console.log(`[EVENTS] Published/Updated event: ${newEvt.title}`);
  res.json({ success: true, event: newEvt });
});

// DELETE /events/:id
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  events = events.filter(e => e.id !== id);
  res.json({ success: true, message: `Event ${id} removed` });
});

export default router;
