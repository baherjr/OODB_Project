const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('../db');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'DatabaseSecretKey';

// Register customer
router.post('/register', async (req, res) => {
  const {
    username, first_name, last_name,
    email, phone, password
  } = req.body;

  try {
    // Check if email already exists
    const existing = await pool.query('SELECT * FROM customers WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Get the last customer_id and increment it
    const lastCustomer = await pool.query('SELECT customer_id FROM customers ORDER BY customer_id DESC LIMIT 1');
    console.log(lastCustomer.rows);

    let newCustomerId;
    if (lastCustomer.rows.length > 0) {
      const lastCustomerId = lastCustomer.rows[0].customer_id; // e.g., "C1050"
      const numericPart = parseInt(lastCustomerId.substring(1), 10); // Extract numeric part (1050)
      newCustomerId = `C${numericPart + 1}`; // Increment and prepend "C"
    } else {
      newCustomerId = 'C1'; // Default for the first customer
    }
    console.log(newCustomerId);

    const password_hash = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO customers (
         customer_id, username, first_name, last_name,
         email, phone, password_hash
       ) VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING customer_id, username, email`,
      [newCustomerId, username, first_name, last_name, email, phone, password_hash]
    );

    res.status(201).json({ message: 'Registration successful', user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Login customer
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Check for admin credentials
    if (email === 'car_admin@gmail.com' && password === 'baherjr') {
      const token = jwt.sign({ role: 'admin', email }, JWT_SECRET, { expiresIn: '1d' });
      return res.json({ message: 'Welcome Admin', token });
    }

    // Regular user login
    const result = await pool.query('SELECT * FROM customers WHERE email = $1', [email]);
    const user = result.rows[0];

    if (!user) {
      return res.status(400).json({ error: 'Invalid email or password' });
    }

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(400).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign({ customer_id: user.customer_id, email: user.email }, JWT_SECRET, {
      expiresIn: '1d',
    });

    res.json({ message: 'Login successful', token });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get user details
router.get('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'SELECT customer_id, username, first_name, last_name, email, phone FROM customers WHERE customer_id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.status(200).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Edit user details
router.put('/edit/:id', async (req, res) => {
  const { id } = req.params;
  const { username, first_name, last_name, email, phone, password } = req.body;

  try {
    const existing = await pool.query('SELECT * FROM customers WHERE customer_id = $1', [id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    let password_hash = existing.rows[0].password_hash;
    if (password) {
      password_hash = await bcrypt.hash(password, 10);
    }

    const result = await pool.query(
      `UPDATE customers SET
         username = $1, first_name = $2, last_name = $3, email = $4, phone = $5, password_hash = $6
       WHERE customer_id = $7
       RETURNING customer_id, username, first_name, last_name, email, phone`,
      [username, first_name, last_name, email, phone, password_hash, id]
    );

    res.status(200).json({ message: 'User updated successfully', user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
