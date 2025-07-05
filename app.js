const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Routes
const vehicleRoutes = require('./routes/vehicles');
const carRoutes = require('./routes/cars');
const sedanRoutes = require('./routes/sedans');
const suvRoutes = require('./routes/suvs');
const truckRoutes = require('./routes/trucks');
const vehiclePartsRoutes = require('./routes/vehicleParts');
const partsRoutes = require('./routes/parts');
const authRoutes = require('./routes/users');
const salesRoutes = require('./routes/sales');

app.use('/api/vehicles', vehicleRoutes);
app.use('/api/cars', carRoutes);
app.use('/api/sedans', sedanRoutes);
app.use('/api/trucks', suvRoutes);
app.use('/api/suvs', truckRoutes);
app.use('/api/parts', partsRoutes);
app.use('/api/vehicleParts', vehiclePartsRoutes);
app.use('/api/user', authRoutes);
app.use('/api/sales', salesRoutes);



const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
