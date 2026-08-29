import { Router, Request, Response } from 'express';
import * as fs from 'fs';
import * as path from 'path';

const router = Router();
const DATA_FILE = path.join(__dirname, '../../data/food_orders.json');

// Ensure data dir and file exist
if (!fs.existsSync(path.dirname(DATA_FILE))) {
  fs.mkdirSync(path.dirname(DATA_FILE), { recursive: true });
}
if (!fs.existsSync(DATA_FILE)) {
  fs.writeFileSync(DATA_FILE, JSON.stringify([]));
}

function readOrders(): any[] {
  try {
    const raw = fs.readFileSync(DATA_FILE, 'utf8');
    return JSON.parse(raw) || [];
  } catch (_) {
    return [];
  }
}

function writeOrders(orders: any[]) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(orders, null, 2));
}

// GET all orders
router.get('/', (req: Request, res: Response) => {
  const orders = readOrders();
  res.json({ success: true, orders });
});

// POST / create or update order
router.post('/', (req: Request, res: Response) => {
  const order = req.body;
  if (!order || !order.id) {
    return res.status(400).json({ error: 'Order data with id is required' });
  }

  const orders = readOrders();
  const idx = orders.findIndex(o => o.id === order.id);
  if (idx !== -1) {
    orders[idx] = { ...orders[idx], ...order, updatedAt: new Date().toISOString() };
  } else {
    orders.unshift({ ...order, createdAt: new Date().toISOString() });
  }

  writeOrders(orders);
  res.json({ success: true, order });
});

// PATCH update status
router.patch('/:id/status', (req: Request, res: Response) => {
  const { id } = req.params;
  const { status, estimatedDeliveryTime, cancellationReason } = req.body;

  const orders = readOrders();
  const idx = orders.findIndex(o => o.id === id);
  if (idx === -1) {
    return res.status(404).json({ error: 'Order not found' });
  }

  orders[idx].status = status || orders[idx].status;
  if (estimatedDeliveryTime) orders[idx].estimatedDeliveryTime = estimatedDeliveryTime;
  if (cancellationReason) orders[idx].cancellationReason = cancellationReason;
  orders[idx].updatedAt = new Date().toISOString();

  writeOrders(orders);
  res.json({ success: true, order: orders[idx] });
});

export default router;
