const express = require('express');
const router = express.Router();
const pool = require('../db');

// Add an SUV
router.post('/', async (req, res) => {
  const {
    vehicle_id, make, model, year, vin, purchase_price, price,
    date_acquired, status, body_type, fuel_type, transmission, mileage,
    engine_size, seating_capacity, cargo_capacity, ground_clearance, awd_4wd
  } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO suvs (
         vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status,
         body_type, fuel_type, transmission, mileage, engine_size,
         seating_capacity, cargo_capacity, ground_clearance, awd_4wd
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9,
                 $10, $11, $12, $13, $14, $15, $16, $17, $18)
       RETURNING *`,
      [vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status,
       body_type, fuel_type, transmission, mileage, engine_size,
       seating_capacity, cargo_capacity, ground_clearance, awd_4wd]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Edit an SUV
router.put('/edit/:id', async (req, res) => {
  const { id } = req.params;
  const {
    vehicle_id, make, model, year, vin, purchase_price, price,
    date_acquired, status, body_type, fuel_type, transmission, mileage,
    engine_size, seating_capacity, cargo_capacity, ground_clearance, awd_4wd
  } = req.body;

  try {
    const result = await pool.query(
      `UPDATE suvs SET
         vehicle_id = $1, make = $2, model = $3, year = $4, vin = $5, purchase_price = $6, 
         price = $7, date_acquired = $8, status = $9, body_type = $10, fuel_type = $11, 
         transmission = $12, mileage = $13, engine_size = $14, seating_capacity = $15, 
         cargo_capacity = $16, ground_clearance = $17, awd_4wd = $18
       WHERE id = $19
       RETURNING *`,
      [vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status,
       body_type, fuel_type, transmission, mileage, engine_size, seating_capacity,
       cargo_capacity, ground_clearance, awd_4wd, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'SUV not found' });
    }

    res.status(200).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete an SUV
router.delete('/delete/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `DELETE FROM suvs WHERE id = $1 RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'SUV not found' });
    }

    res.status(200).json({ message: 'SUV deleted successfully', suv: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
