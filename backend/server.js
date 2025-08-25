const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL bağlantısı
const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'counterdb',
    password: process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 5432,
});

// Database bağlantısını test et
pool.connect()
    .then(() => console.log('PostgreSQL veritabanına bağlandı'))
    .catch(err => console.error('Veritabanı bağlantı hatası:', err));

// Routes

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Counter değerini getir
app.get('/api/counter', async (req, res) => {
    try {
        const result = await pool.query('SELECT count FROM counter WHERE id = 1');
        
        if (result.rows.length === 0) {
            // İlk kez çalışıyorsa, counter oluştur
            await pool.query('INSERT INTO counter (id, count) VALUES (1, 0)');
            res.json({ count: 0 });
        } else {
            res.json({ count: result.rows[0].count });
        }
    } catch (error) {
        console.error('Counter getirme hatası:', error);
        res.status(500).json({ error: 'Veritabanı hatası' });
    }
});

// Counter'ı artır
app.post('/api/counter/increment', async (req, res) => {
    try {
        const result = await pool.query(
            'UPDATE counter SET count = count + 1 WHERE id = 1 RETURNING count'
        );
        
        if (result.rows.length === 0) {
            // Counter yoksa oluştur ve 1 yap
            await pool.query('INSERT INTO counter (id, count) VALUES (1, 1)');
            res.json({ count: 1 });
        } else {
            res.json({ count: result.rows[0].count });
        }
    } catch (error) {
        console.error('Counter artırma hatası:', error);
        res.status(500).json({ error: 'Veritabanı hatası' });
    }
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ error: 'Endpoint bulunamadı' });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Sunucu hatası' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server ${PORT} portunda çalışıyor`);
});
