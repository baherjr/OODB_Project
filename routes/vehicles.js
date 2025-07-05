const express = require('express');
const router = express.Router();
const pool = require('../db');

// Get all vehicles
router.get('/', async (req, res) => {
  const { status } = req.query; // Get the status from query parameters

  try {
    let query = 'SELECT DISTINCT * FROM vehicles';
        const values = [];

    if (status && status !== 'All') {
      query += ' WHERE status = $1';
      values.push(status);
    }

    const result = await pool.query(query, values);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Add a new vehicle with auto-incremented ID
router.post('/add', async (req, res) => {
  const { make, model, year, vin, purchase_price, price, date_acquired, status } = req.body;

  try {
    // Get the last vehicle_id from the database
    const lastVehicle = await pool.query('SELECT vehicle_id FROM vehicles ORDER BY vehicle_id DESC LIMIT 1');

    let newVehicleId;
    if (lastVehicle.rows.length > 0) {
      const lastVehicleId = lastVehicle.rows[0].vehicle_id; // e.g., "V10"
      console
      const numericPart = parseInt(lastVehicleId.substring(1), 10); // Extract numeric part (10)
      newVehicleId = `V${numericPart + 1}`; // Increment and prepend "V"
    } else {
      newVehicleId = 'V1'; // Default for the first vehicle
    }

    // Insert the new vehicle into the database
    const query = `INSERT INTO vehicles (vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status) 
                   VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`;
    const values = [newVehicleId, make, model, year, vin, purchase_price, price, date_acquired, status];
    await pool.query(query, values);

    res.status(201).json({ message: 'Vehicle added successfully', vehicle_id: newVehicleId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update a vehicle
router.put('/edit/:id', async (req, res) => {
  const { id } = req.params;
  const { make, model, year, vin, purchase_price, price, date_acquired, status } = req.body;
  try {
    const query = `UPDATE vehicles SET make = $1, model = $2, year = $3, vin = $4, purchase_price = $5, price = $6, 
                   date_acquired = $7, status = $8, updated_at = CURRENT_TIMESTAMP WHERE vehicle_id = $9`;
    const values = [make, model, year, vin, purchase_price, price, date_acquired, status, id];
    const result = await pool.query(query, values);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Vehicle not found' });
    }
    res.json({ message: 'Vehicle updated successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get a single vehicle by ID
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const query = 'SELECT * FROM vehicles WHERE vehicle_id = $1';
    const values = [id];
    const result = await pool.query(query, values);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Vehicle not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a vehicle
router.delete('/delete/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const query = 'DELETE FROM vehicles WHERE vehicle_id = $1';
    const values = [id];
    const result = await pool.query(query, values);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Vehicle not found' });
    }
    res.json({ message: 'Vehicle deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
