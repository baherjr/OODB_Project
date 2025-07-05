const express = require('express');
const router = express.Router();
const pool = require('../db');

// Add a car
router.post('/add', async (req, res) => {
  const {
    vehicle_id,
    make,
    model,
    year,
    vin,
    purchase_price,
    price,
    date_acquired,
    status,
    body_type,
    fuel_type,
    transmission,
    mileage,
    engine_size
  } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO cars (
         vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status,
         body_type, fuel_type, transmission, mileage, engine_size
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
       RETURNING *`,
      [vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status,
       body_type, fuel_type, transmission, mileage, engine_size]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Edit a car
router.put('/edit/:id', async (req, res) => {
  const { id } = req.params;
  const {
    vehicle_id,
    make,
    model,
    year,
    vin,
    purchase_price,
    price,
    date_acquired,
    status,
    body_type,
    fuel_type,
    transmission,
    mileage,
    engine_size
  } = req.body;

  try {
    const result = await pool.query(
      `UPDATE cars SET
         vehicle_id = $1, make = $2, model = $3, year = $4, vin = $5, purchase_price = $6, 
         price = $7, date_acquired = $8, status = $9, body_type = $10, fuel_type = $11, 
         transmission = $12, mileage = $13, engine_size = $14
       WHERE id = $15
       RETURNING *`,
      [vehicle_id, make, model, year, vin, purchase_price, price, date_acquired, status,
       body_type, fuel_type, transmission, mileage, engine_size, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Car not found' });
    }

    res.status(200).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a car
router.delete('/delete/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `DELETE FROM cars WHERE id = $1 RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Car not found' });
    }

    res.status(200).json({ message: 'Car deleted successfully', car: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
