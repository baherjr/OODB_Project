const express = require('express');
const router = express.Router();
const pool = require('../db');

// Add a new part
router.post('/add', async (req, res) => {
  const {
    part_id, name, description, category, part_number,
    price, quantity_in_stock, reorder_threshold,
    reorder_quantity, supplier_id
  } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO parts (
         part_id, name, description, category, part_number,
         price, quantity_in_stock, reorder_threshold,
         reorder_quantity, supplier_id
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        part_id, name, description, category, part_number,
        price, quantity_in_stock, reorder_threshold,
        reorder_quantity, supplier_id
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;
