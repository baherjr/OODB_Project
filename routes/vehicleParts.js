const express = require('express');
const router = express.Router();
const pool = require('../db');

// Add part to a vehicle
router.post('/add', async (req, res) => {
  const { vehicle_id, part_id, quantity, installed_date } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO vehicle_parts (
         vehicle_id, part_id, quantity, installed_date
       ) VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [vehicle_id, part_id, quantity, installed_date || null]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;
