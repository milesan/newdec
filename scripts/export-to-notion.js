import { Client } from '@notionhq/client';
import { config } from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import { format } from 'date-fns';

// Load environment variables
config();

// Initialize Notion client
const notion = new Client({
  auth: process.env.NOTION_TOKEN,
});

// Initialize Supabase client
const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

const APPLICATIONS_DATABASE_ID = process.env.NOTION_APPLICATIONS_DATABASE_ID;
const BOOKINGS_DATABASE_ID = process.env.NOTION_BOOKINGS_DATABASE_ID;

async function exportApplications() {
  try {
    // Fetch all applications with user data
    const { data: applications, error } = await supabase
      .from('application_details')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    // Process each application
    for (const app of applications) {
      const properties = {
        Name: {
          title: [
            {
              text: {
                content: `${app.data[4]} ${app.data[5]}`,
              },
            },
          ],
        },
        Email: {
          email: app.user_email,
        },
        Status: {
          select: {
            name: app.status.charAt(0).toUpperCase() + app.status.slice(1),
          },
        },
        "Created At": {
          date: {
            start: app.created_at,
          },
        },
        "Linked With": {
          rich_text: [
            {
              text: {
                content: app.linked_name ? `${app.linked_name} (${app.linked_email})` : 'None',
              },
            },
          ],
        },
        "Current Location": {
          rich_text: [
            {
              text: {
                content: app.data[6] || 'Not specified',
              },
            },
          ],
        },
        "Referral": {
          rich_text: [
            {
              text: {
                content: app.data[7] || 'None',
              },
            },
          ],
        },
        "Muse/Artisan": {
          select: {
            name: app.data[8]?.answer || 'Not specified',
          },
        },
        "WhatsApp": {
          phone_number: app.data[9] || '',
        },
        "Social Media": {
          url: app.data[10] || null,
        },
        "Life Status": {
          rich_text: [
            {
              text: {
                content: app.data[11] || '',
              },
            },
          ],
        },
        "Why Garden": {
          rich_text: [
            {
              text: {
                content: app.data[12] || '',
              },
            },
          ],
        },
        "MBTI": {
          rich_text: [
            {
              text: {
                content: app.data[30] || 'Not specified',
              },
            },
          ],
        },
      };

      // Create or update page in Notion
      await notion.pages.create({
        parent: { database_id: APPLICATIONS_DATABASE_ID },
        properties,
      });
    }

    console.log('Successfully exported applications to Notion');
  } catch (error) {
    console.error('Error exporting applications:', error);
  }
}

async function exportBookings() {
  try {
    // Fetch all confirmed bookings with related data
    const { data: bookings, error } = await supabase
      .from('booking_details')
      .select('*')
      .eq('status', 'confirmed')
      .order('check_in', { ascending: true });

    if (error) throw error;

    // Process each booking
    for (const booking of bookings) {
      const properties = {
        "Guest": {
          title: [
            {
              text: {
                content: booking.user_email,
              },
            },
          ],
        },
        "Accommodation": {
          select: {
            name: booking.accommodation_title,
          },
        },
        "Check In": {
          date: {
            start: format(new Date(booking.check_in), 'yyyy-MM-dd'),
          },
        },
        "Check Out": {
          date: {
            start: format(new Date(booking.check_out), 'yyyy-MM-dd'),
          },
        },
        "Total Price": {
          number: booking.total_price,
        },
        "Status": {
          select: {
            name: booking.status.charAt(0).toUpperCase() + booking.status.slice(1),
          },
        },
        "Created At": {
          date: {
            start: booking.created_at,
          },
        },
        "Location": {
          rich_text: [
            {
              text: {
                content: booking.accommodation_location,
              },
            },
          ],
        },
        "Type": {
          select: {
            name: booking.accommodation_type,
          },
        },
        "Duration (Weeks)": {
          number: Math.ceil(
            (new Date(booking.check_out) - new Date(booking.check_in)) / 
            (1000 * 60 * 60 * 24 * 7)
          ),
        },
      };

      // Create or update page in Notion
      await notion.pages.create({
        parent: { database_id: BOOKINGS_DATABASE_ID },
        properties,
      });
    }

    console.log('Successfully exported bookings to Notion');
  } catch (error) {
    console.error('Error exporting bookings:', error);
  }
}

// Run both exports
async function main() {
  await exportApplications();
  await exportBookings();
}

main();