import { 
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  onSnapshot
} from 'firebase/firestore';
import { db } from './config';
import { getBlogImage, assignBlogImage } from '../utils/blogImageMapping';

// Collections
const PROPERTIES_COLLECTION = 'properties';
const PROPERTY_VIEWINGS_COLLECTION = "viewingRequests"; 
const RENTAL_PROPERTIES_COLLECTION = 'rentalProperties'; // NEW: For rental forms
const SALE_PROPERTIES_COLLECTION = 'saleProperties'; // NEW: For sale forms
const USERS_COLLECTION = 'users';
const BLOGS_COLLECTION = 'blogs';
const CONTACTS_COLLECTION = 'contacts';
const REVIEWS_COLLECTION = 'reviews'; // NEW: For testimonials/reviews
const AGENTS_COLLECTION = 'agents'; // NEW: For agents collection

const RESIDENTIAL_PORTFOLIO = "residentialPortfolio";
const LAND_PORTFOLIO = "landPortfolio";

const COLLECTIONS = [
  { key: "residential", name: "residentialPortfolio" },
  { key: "land", name: "landPortfolio" },
];


// Property operations
export const addProperty = async (propertyData) => {
  try {
    const docRef = await addDoc(collection(db, PROPERTIES_COLLECTION), {
      ...propertyData,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    return { success: true, id: docRef.id };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// NEW: Add rental property from agent form
export const addRentalProperty = async (rentalData, agentInfo) => {
  try {
    const docRef = await addDoc(collection(db, RENTAL_PROPERTIES_COLLECTION), {
      ...rentalData,
      agentInfo: {
        email: agentInfo.email,
        name: agentInfo.name,
        role: agentInfo.role
      },
      status: 'pending', // pending, approved, rejected
      submittedAt: new Date(),
      createdAt: new Date(),
      updatedAt: new Date()
    });
    return { success: true, id: docRef.id };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// NEW: Add sale property from agent form
export const addSaleProperty = async (saleData, agentInfo) => {
  try {
    console.log('Adding sale property to collection:', SALE_PROPERTIES_COLLECTION);
    const docRef = await addDoc(collection(db, SALE_PROPERTIES_COLLECTION), {
      ...saleData,
      agentInfo: {
        email: agentInfo.email,
        name: agentInfo.name,
        role: agentInfo.role
      },
      status: 'pending', // pending, approved, rejected
      submittedAt: new Date(),
      createdAt: new Date(),
      updatedAt: new Date()
    });
    return { success: true, id: docRef.id };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// ===============================================
// ⭐ UPDATE RENTAL PROPERTY — ADMIN PANEL
// ===============================================
export const adminUpdateRentalProperty = async (rentalId, updateData, adminInfo = {}) => {
  try {
    const docRef = doc(db, RENTAL_PROPERTIES_COLLECTION, rentalId);

    await updateDoc(docRef, {
      ...updateData,
      updatedAt: new Date(),
      reviewedAt: new Date(),
      lastUpdatedByAdmin: {
        name: adminInfo.name || "Unknown Admin",
        email: adminInfo.email || "",
        role: adminInfo.role || "admin"
      }
    });

    return { success: true };
  } catch (error) {
    console.error("Admin update rental error:", error);
    return { success: false, error: error.message };
  }
};

export const adminUpdateRentalPropertyAll = async (rentalId, data, adminInfo = {}) => {
  try {
    const ref = doc(db, RENTAL_PROPERTIES_COLLECTION, rentalId);

    await updateDoc(ref, {
      // -------- BASIC --------
      title: data.title || "",
      notes: data.notes || "",
      status: data.status || "available",
      type: data.type || "",

      // -------- PROPERTY INFO --------
      property: {
        propertyInfo: {
          id: data.property?.propertyInfo?.id || "",
          name: data.property?.propertyInfo?.name || "",
          type: data.property?.propertyInfo?.type || "",
          status: data.property?.propertyInfo?.status || "",
          pricePerNight: data.property?.propertyInfo?.pricePerNight || "",
        }
      },

      // -------- ACCOMMODATION --------
      accommodation: {
        bedrooms: data.accommodation?.bedrooms || "",
        bathrooms: data.accommodation?.bathrooms || "",
        maxOccupancy: data.accommodation?.maxOccupancy || "",
      },

      // -------- DETAILS --------
      details: {
        squareFeet: data.details?.squareFeet || "",
        yearBuilt: data.details?.yearBuilt || "",
        lotSize: data.details?.lotSize || "",
      },

      // -------- IMAGES --------
     image: data.image || "",
      media: {
        imageList: data.media?.imageList || [],
        imageLinks: data.media?.imageList || [],   // backward compatibility
      },

      // -------- RATES --------
      rates: {
        baseRate: data.rates?.baseRate || "",
        seasonalRate: data.rates?.seasonalRate || "",
      },

      // -------- OFF-SEASON --------
      offSeasonRates: {
        fiveToSix: data.offSeasonRates?.fiveToSix || "",
        oneToFour: data.offSeasonRates?.oneToFour || "",
      },

      // -------- POLICIES --------
      policies: {
        cancellationPolicy: data.policies?.cancellationPolicy || "",
        "check-in": data.policies?.["check-in"] || "",
        "check-out": data.policies?.["check-out"] || "",
        damagePolicy: data.policies?.damagePolicy || "",
      },

      // -------- FLAGS --------
      smoking: data.smoking ?? false,
      pets: data.pets ?? false,
      party: data.party ?? false,
      children: data.children ?? false,

      // -------- CONTACT --------
      contact: {
        managerName: data.contact?.managerName || "",
        managerEmail: data.contact?.managerEmail || "",
      },

      // -------- SYSTEM --------
      submittedAt: data.submittedAt || null,
      reviewedAt: new Date(),
      updatedAt: new Date(),

      // -------- ADMIN TRACKING --------
      lastUpdatedByAdmin: {
        name: adminInfo.name || "Admin",
        email: adminInfo.email || "",
        role: adminInfo.role || "admin",
      }
    });

    return { success: true };

  } catch (error) {
    console.error("Admin FULL update error:", error);
    return { success: false, error: error.message };
  }
};


export const getProperty = async (propertyId) => {
  try {
    const docRef = doc(db, PROPERTIES_COLLECTION, propertyId);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      return { success: true, data: { id: docSnap.id, ...docSnap.data() } };
    } else {
      return { success: false, error: 'Property not found' };
    }
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const getProperties = async (filters = {}, limitCount = 10) => {
  try {
    let q = collection(db, PROPERTIES_COLLECTION);
    
    // Apply filters
    if (filters.type) {
      q = query(q, where('type', '==', filters.type));
    }
    if (filters.status) {
      q = query(q, where('status', '==', filters.status));
    }
    if (filters.minPrice) {
      q = query(q, where('price', '>=', filters.minPrice));
    }
    if (filters.maxPrice) {
      q = query(q, where('price', '<=', filters.maxPrice));
    }
    
    // Apply ordering and limit
    q = query(q, orderBy('createdAt', 'desc'), limit(limitCount));
    
    const querySnapshot = await getDocs(q);
    const properties = [];
    
    querySnapshot.forEach((doc) => {
      properties.push({ id: doc.id, ...doc.data() });
    });
    
    return { success: true, data: properties };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// NEW: Get rental properties for admin approval
export const getRentalProperties = async (filters = {}) => {
  try {
    let q = collection(db, RENTAL_PROPERTIES_COLLECTION);
    
    // Apply filters
    if (filters.status) {
      q = query(q, where('status', '==', filters.status));
    }
    if (filters.agentEmail) {
      q = query(q, where('agentInfo.email', '==', filters.agentEmail));
    }
    
    // Remove ordering temporarily to avoid index requirement
    // q = query(q, orderBy('submittedAt', 'desc'));
    
    const querySnapshot = await getDocs(q);
    const rentalProperties = [];
    
    querySnapshot.forEach((doc) => {
      rentalProperties.push({ id: doc.id, ...doc.data() });
    });
    
    // Sort in JavaScript instead of Firestore
    if (rentalProperties.length > 0) {
      rentalProperties.sort((a, b) => {
        const dateA = a.submittedAt?.toDate?.() || new Date(a.submittedAt) || new Date(0);
        const dateB = b.submittedAt?.toDate?.() || new Date(b.submittedAt) || new Date(0);
        return dateB - dateA; // Descending order
      });
    }
    
    return { success: true, data: rentalProperties };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// NEW: Get rental properties BY  ID  
export const getAllRentalProperties = async () => {
  try {
    const q = collection(db, RENTAL_PROPERTIES_COLLECTION);
    const querySnapshot = await getDocs(q);

    const properties = [];

    querySnapshot.forEach((doc) => {
      properties.push({ id: doc.id, ...doc.data() });
    });

    return { success: true, data: properties };
  } catch (error) {
    return { success: false, error: error.message };
  }
};


// =====================================================
// ⭐ Get SINGLE rental property by ID
// =====================================================
export const getRentalPropertyById = async (rentalId) => {
  try {
    const ref = doc(db, RENTAL_PROPERTIES_COLLECTION, rentalId);
    const snap = await getDoc(ref);

    if (!snap.exists()) {
      return { success: false, error: "Rental property not found" };
    }

    return {
      success: true,
      data: { id: snap.id, ...snap.data() }
    };

  } catch (error) {
    console.error("Error fetching rental property:", error);
    return { success: false, error: error.message };
  }
};


export const updateRentalProperty = async (id, data, agentInfo) => {
  try {
    const ref = doc(db, "rentalProperties", id);
    await updateDoc(ref, {
      ...data,
      updatedAt: new Date(),
      lastUpdatedBy: agentInfo
    });

    return { success: true };
  } catch (err) {
    console.error(err);
    return { success: false, error: err.message };
  }
};

//  Add Today By himanshu Bhagat 

// NEW: Get sale properties for admin approval
export const getSaleProperties = async (filters = {}) => {
  try {
    let q = collection(db, SALE_PROPERTIES_COLLECTION);

    // Normalize status filter
    if (filters.status) {
      q = query(q, where("status", "==", filters.status.toLowerCase()));
    }

    const snap = await getDocs(q);
    const list = [];

    snap.forEach((doc) => {
      const data = doc.data();

      // Normalize Firestore status
      data.status = data.status?.toLowerCase();

      // Match whatever case stored in DB
      if (!filters.status || data.status === filters.status.toLowerCase()) {
        list.push({ id: doc.id, ...data });
      }
    });

    return { success: true, data: list };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const updateProperty = async (propertyId, updateData) => {
  try {
    const docRef = doc(db, PROPERTIES_COLLECTION, propertyId);
    await updateDoc(docRef, {
      ...updateData,
      updatedAt: new Date()
    });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// NEW: Update rental property status (for admin approval/rejection)
export const updateRentalPropertyStatus = async (rentalId, status, adminNotes = '') => {
  try {
    const docRef = doc(db, RENTAL_PROPERTIES_COLLECTION, rentalId);
    await updateDoc(docRef, {
      status: status,
      adminNotes: adminNotes,
      reviewedAt: new Date(),
      updatedAt: new Date()
    });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// NEW: Delete rental property (admin only)
export const deleteRentalProperty = async (rentalId) => {
  try {
    const docRef = doc(db, RENTAL_PROPERTIES_COLLECTION, rentalId);
    await deleteDoc(docRef);
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// NEW: Update sale property status (for admin approval/rejection)
export const updateSalePropertyStatus = async (saleId, status, adminNotes = '') => {
  try {
    const docRef = doc(db, SALE_PROPERTIES_COLLECTION, saleId);
    await updateDoc(docRef, {
      status: status,
      adminNotes: adminNotes,
      reviewedAt: new Date(),
      updatedAt: new Date()
    });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// NEW: Delete sale property (admin only)
export const deleteSaleProperty = async (saleId) => {
  try {
    const docRef = doc(db, SALE_PROPERTIES_COLLECTION, saleId);
    await deleteDoc(docRef);
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Sold Properties Collection
const SOLD_PROPERTIES_COLLECTION = 'soldProperties';

export const addSoldProperty = async (soldData, agentInfo) => {
  try {
    console.log('Adding sold property to collection:', SOLD_PROPERTIES_COLLECTION);
    const docRef = await addDoc(collection(db, SOLD_PROPERTIES_COLLECTION), {
      ...soldData,
      agentInfo: {
        email: agentInfo.email,
        name: agentInfo.name,
        role: agentInfo.role
      },
      status: 'pending',
      submittedAt: new Date(),
      createdAt: new Date(),
      updatedAt: new Date()
    });
    return { success: true, id: docRef.id };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const getSoldProperties = async (filters = {}) => {
  try {
    const ref = collection(db, SOLD_PROPERTIES_COLLECTION);
    const snap = await getDocs(ref);

    const list = snap.docs.map(doc => {
      const data = doc.data();
      return { id: doc.id, ...data, status: (data.status || "").toLowerCase().trim() };
    });

    if (filters.status) {
      const status = filters.status.toLowerCase().trim();
      return { success: true, data: list.filter(item => item.status === status) };
    }

    return { success: true, data: list };

  } catch (error) {
    return { success: false, error: error.message };
  }
};


export const updateSoldPropertyStatus = async (soldId, status, adminNotes = '') => {
  try {
    const docRef = doc(db, SOLD_PROPERTIES_COLLECTION, soldId);
    await updateDoc(docRef, {
      status: status,
      adminNotes: adminNotes,
      reviewedAt: new Date(),
      updatedAt: new Date()
    });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// NEW: Delete sold property (admin only)
export const deleteSoldProperty = async (soldId) => {
  try {
    const docRef = doc(db, SOLD_PROPERTIES_COLLECTION, soldId);
    await deleteDoc(docRef);
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const deleteProperty = async (propertyId) => {
  try {
    await deleteDoc(doc(db, PROPERTIES_COLLECTION, propertyId));
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};


// ✔ Get all users
export const getAllUsers = async () => {
  try {
    const snap = await getDocs(collection(db, USERS_COLLECTION));
    const list = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    return { success: true, data: list };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// ✔ Update user (role or anything)
export const updateUser = async (id, data) => {
  try {
    await updateDoc(doc(db, USERS_COLLECTION, id), data);
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// ✔ Delete user
export const deleteUser = async (id) => {
  try {
    await deleteDoc(doc(db, USERS_COLLECTION, id));
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// ✔ Create user manually (optional)
export const addUserWithRole = async (id, userData) => {
  try {
    await setDoc(doc(db, USERS_COLLECTION, id), userData);
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// User operations
export const addUser = async (userData) => {
  try {
    // Use the UID as the document ID for consistency
    const docRef = doc(db, USERS_COLLECTION, userData.uid);
    await setDoc(docRef, {
      ...userData,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    return { success: true, id: userData.uid };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const getUser = async (userId) => {
  try {
    const docRef = doc(db, USERS_COLLECTION, userId);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      return { success: true, data: { id: docSnap.id, ...docSnap.data() } };
    } else {
      return { success: false, error: 'User not found' };
    }
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Blog operations with hardcoded image mapping
export const addBlog = async (blogData) => {
  try {
    // Assign hardcoded image if none provided
    const blogWithImage = assignBlogImage(blogData);
    
    const docRef = await addDoc(collection(db, BLOGS_COLLECTION), {
      ...blogWithImage,
      createdAt: new Date(),
      updatedAt: new Date(),
      views: 0,
      likes: 0,
      status: blogWithImage.status || 'published'
    });
    return { success: true, id: docRef.id };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const getBlogs = async (limitCount = 10) => {
  try {
    // Simplified query without composite index requirement
    const q = query(
      collection(db, BLOGS_COLLECTION),
      orderBy('createdAt', 'desc'),
      limit(limitCount)
    );
    
    const querySnapshot = await getDocs(q);
    const blogs = [];
    
    querySnapshot.forEach((doc) => {
      const blogData = { id: doc.id, ...doc.data() };
      
      // Filter for published blogs in JavaScript instead of Firestore
      if (blogData.status === 'published' || !blogData.status) {
        // Ensure blog has an image using our mapping system
        if (!blogData.coverImage) {
          blogData.coverImage = getBlogImage(blogData);
        }
        
        blogs.push(blogData);
      }
    });
    
    // Return only the requested number of published blogs
    return { success: true, data: blogs.slice(0, limitCount) };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const getBlog = async (blogId) => {
  try {
    const docRef = doc(db, BLOGS_COLLECTION, blogId);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      const blogData = { id: docSnap.id, ...docSnap.data() };
      
      // Ensure blog has an image using our mapping system
      if (!blogData.coverImage) {
        blogData.coverImage = getBlogImage(blogData);
      }
      
      // Increment view count
      updateDoc(docRef, {
        views: (blogData.views || 0) + 1,
        lastViewed: new Date()
      }).catch(err => console.log('View count update failed:', err));
      
      return { success: true, data: blogData };
    } else {
      return { success: false, error: 'Blog not found' };
    }
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const updateBlog = async (blogId, updateData) => {
  try {
    // Assign hardcoded image if none provided in update
    const blogWithImage = assignBlogImage(updateData);
    
    const docRef = doc(db, BLOGS_COLLECTION, blogId);
    await updateDoc(docRef, {
      ...blogWithImage,
      updatedAt: new Date()
    });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Enhanced blog functions for admin management
export const getAllBlogsForAdmin = async (limitCount = 50) => {
  try {
    // Simple query without complex indexing requirements
    const q = query(
      collection(db, BLOGS_COLLECTION),
      orderBy('createdAt', 'desc'),
      limit(limitCount)
    );
    
    const querySnapshot = await getDocs(q);
    const blogs = [];
    
    querySnapshot.forEach((doc) => {
      const blogData = { id: doc.id, ...doc.data() };
      
      // Ensure blog has an image using our mapping system
      if (!blogData.coverImage) {
        blogData.coverImage = getBlogImage(blogData);
      }
      
      blogs.push(blogData);
    });
    
    return { success: true, data: blogs };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Bulk add blogs (for migration from static data)
export const bulkAddBlogs = async (blogsArray) => {
  try {
    const results = [];
    for (const blogData of blogsArray) {
      const result = await addBlog(blogData);
      results.push(result);
    }
    return { success: true, results };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Toggle blog status (publish/unpublish)
export const toggleBlogStatus = async (blogId, currentStatus) => {
  try {
    const newStatus = currentStatus === 'published' ? 'draft' : 'published';
    const docRef = doc(db, BLOGS_COLLECTION, blogId);
    await updateDoc(docRef, {
      status: newStatus,
      updatedAt: new Date(),
      ...(newStatus === 'published' && { publishedAt: new Date() })
    });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const deleteBlog = async (blogId) => {
  try {
    await deleteDoc(doc(db, BLOGS_COLLECTION, blogId));
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Contact form submissions
export const submitContact = async (contactData) => {
  try {
    const docRef = await addDoc(collection(db, CONTACTS_COLLECTION), {
      ...contactData,
      createdAt: new Date(),
      status: 'new'
    });
    return { success: true, id: docRef.id };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Real-time listeners
export const subscribeToProperties = (callback, filters = {}) => {
  let q = collection(db, PROPERTIES_COLLECTION);
  
  if (filters.type) {
    q = query(q, where('type', '==', filters.type));
  }
  if (filters.status) {
    q = query(q, where('status', '==', filters.status));
  }
  
  q = query(q, orderBy('createdAt', 'desc'));
  
  return onSnapshot(q, (querySnapshot) => {
    const properties = [];
    querySnapshot.forEach((doc) => {
      properties.push({ id: doc.id, ...doc.data() });
    });
    callback(properties);
  });
};

// Review operations
export const addReview = async (reviewData) => {
  try {
    console.log('Adding review to Firebase:', reviewData);
    const docRef = await addDoc(collection(db, REVIEWS_COLLECTION), {
      ...reviewData,
      status: 'approved', // Auto-approve reviews for now
      createdAt: new Date(),
      updatedAt: new Date()
    });
    console.log('Review added successfully with ID:', docRef.id);
    return { success: true, id: docRef.id };
  } catch (error) {
    console.error('Error adding review:', error);
    return { success: false, error: error.message };
  }
};

export const getReviews = async (limitCount = 50) => {
  try {
    const q = query(
      collection(db, REVIEWS_COLLECTION),
      where('status', '==', 'approved')
    );
    
    const querySnapshot = await getDocs(q);
    const reviews = [];
    
    querySnapshot.forEach((doc) => {
      reviews.push({ id: doc.id, ...doc.data() });
    });
    
    // Sort in JavaScript instead of Firestore to avoid index requirement
    reviews.sort((a, b) => {
      const dateA = a.createdAt?.toDate?.() || new Date(a.createdAt) || new Date(0);
      const dateB = b.createdAt?.toDate?.() || new Date(b.createdAt) || new Date(0);
      return dateB - dateA; // Descending order (newest first)
    });
    
    // Apply limit after sorting
    const limitedReviews = reviews.slice(0, limitCount);
    
    return { success: true, data: limitedReviews };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Real-time reviews listener
export const subscribeToReviews = (callback) => {
  console.log('Setting up reviews listener...');
  const q = query(
    collection(db, REVIEWS_COLLECTION),
    where('status', '==', 'approved')
  );
  
  return onSnapshot(q, (querySnapshot) => {
    console.log('Firebase reviews snapshot received, docs count:', querySnapshot.size);
    const reviews = [];
    querySnapshot.forEach((doc) => {
      reviews.push({ id: doc.id, ...doc.data() });
    });
    
    // Sort in JavaScript instead of Firestore to avoid index requirement
    reviews.sort((a, b) => {
      const dateA = a.createdAt?.toDate?.() || new Date(a.createdAt) || new Date(0);
      const dateB = b.createdAt?.toDate?.() || new Date(b.createdAt) || new Date(0);
      return dateB - dateA; // Descending order (newest first)
    });
    
    console.log('Processed reviews:', reviews);
    callback(reviews);
  });
};

// Booking Request operations
export const addBookingRequest = async (rentalPropertyId, bookingData) => {
  try {
    // Add to the bookingRequests subcollection of the rental property
    const bookingRequestsRef = collection(db, 'rentalProperties', rentalPropertyId, 'bookingRequests');
    const docRef = await addDoc(bookingRequestsRef, {
      ...bookingData,
      status: 'pending',
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    console.log('Booking request added with ID:', docRef.id);
    return { success: true, id: docRef.id };
  } catch (error) {
    console.error('Error adding booking request:', error);
    return { success: false, error: error.message };
  }
};

// Villa booking requests - separate collection since villas are static data
export const addVillaBookingRequest = async (villaId, bookingData) => {
  try {
    // Add to the villa bookings collection
    const docRef = await addDoc(collection(db, 'villaBookings'), {
      villaId: villaId,
      ...bookingData,
      status: 'pending',
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    console.log('Villa booking request added with ID:', docRef.id);
    return { success: true, id: docRef.id };
  } catch (error) {
    console.error('Error adding villa booking request:', error);
    return { success: false, error: error.message };
  }
};

export const getVillaBookingRequests = async (filters = {}) => {
  try {
    let q = collection(db, 'villaBookings');
    
    if (filters.villaId) {
      q = query(q, where('villaId', '==', filters.villaId));
    }
    if (filters.status) {
      q = query(q, where('status', '==', filters.status));
    }
    
    const querySnapshot = await getDocs(q);
    const bookingRequests = [];
    
    querySnapshot.forEach((doc) => {
      bookingRequests.push({ id: doc.id, ...doc.data() });
    });
    
    // Sort by creation date
    bookingRequests.sort((a, b) => {
      const dateA = a.createdAt?.toDate?.() || new Date(a.createdAt) || new Date(0);
      const dateB = b.createdAt?.toDate?.() || new Date(b.createdAt) || new Date(0);
      return dateB - dateA;
    });
    
    return { success: true, data: bookingRequests };
  } catch (error) {
    console.error('Error fetching villa booking requests:', error);
    return { success: false, error: error.message };
  }
};

export const updateVillaBookingRequestStatus = async (bookingId, status, adminNotes = '') => {
  try {
    const bookingRef = doc(db, 'villaBookings', bookingId);
    await updateDoc(bookingRef, {
      status,
      adminNotes,
      updatedAt: new Date(),
      ...(status === 'approved' && { approvedAt: new Date() }),
      ...(status === 'rejected' && { rejectedAt: new Date() })
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error updating villa booking request status:', error);
    return { success: false, error: error.message };
  }
};

export const getBookingRequests = async (rentalPropertyId) => {
  try {
    const bookingRequestsRef = collection(db, 'rentalProperties', rentalPropertyId, 'bookingRequests');
    const q = query(bookingRequestsRef, orderBy('createdAt', 'desc'));
    const querySnapshot = await getDocs(q);
    
    const bookingRequests = [];
    querySnapshot.forEach((doc) => {
      bookingRequests.push({ id: doc.id, ...doc.data() });
    });
    
    return { success: true, data: bookingRequests };
  } catch (error) {
    console.error('Error fetching booking requests:', error);
    return { success: false, error: error.message };
  }
};

export const updateBookingRequestStatus = async (rentalPropertyId, bookingRequestId, status, adminNotes = '') => {
  try {
    const bookingRequestRef = doc(db, 'rentalProperties', rentalPropertyId, 'bookingRequests', bookingRequestId);
    await updateDoc(bookingRequestRef, {
      status,
      adminNotes,
      updatedAt: new Date(),
      ...(status === 'approved' && { approvedAt: new Date() }),
      ...(status === 'rejected' && { rejectedAt: new Date() })
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error updating booking request status:', error);
    return { success: false, error: error.message };
  }
};

export const getAllBookingRequestsForAgent = async (agentEmail) => {
  try {
    // First get all rental properties for this agent
    const rentalPropertiesRef = collection(db, 'rentalProperties');
    const agentPropertiesQuery = query(
      rentalPropertiesRef, 
      where('agentInfo.email', '==', agentEmail)
    );
    const agentPropertiesSnapshot = await getDocs(agentPropertiesQuery);
    
    const allBookingRequests = [];
    
    // For each property, get its booking requests
    for (const propertyDoc of agentPropertiesSnapshot.docs) {
      const propertyData = { id: propertyDoc.id, ...propertyDoc.data() };
      
      const bookingRequestsRef = collection(db, 'rentalProperties', propertyDoc.id, 'bookingRequests');
      const bookingQuery = query(bookingRequestsRef, orderBy('createdAt', 'desc'));
      const bookingSnapshot = await getDocs(bookingQuery);
      
      bookingSnapshot.forEach((bookingDoc) => {
        allBookingRequests.push({
          id: bookingDoc.id,
          propertyId: propertyDoc.id,
          propertyName: propertyData.name || propertyData.propertyInfo?.name,
          propertySlug: propertyData.propertyInfo?.slug,
          ...bookingDoc.data()
        });
      });
    }
    
    // Sort all booking requests by creation date
    allBookingRequests.sort((a, b) => {
      const dateA = a.createdAt?.toDate?.() || new Date(a.createdAt) || new Date(0);
      const dateB = b.createdAt?.toDate?.() || new Date(b.createdAt) || new Date(0);
      return dateB - dateA;
    });
    
    return { success: true, data: allBookingRequests };
  } catch (error) {
    console.error('Error fetching agent booking requests:', error);
    return { success: false, error: error.message };
  }
};

export const getAllBookingRequestsForAdmin = async () => {
  try {
    // Get all rental properties
    const rentalPropertiesRef = collection(db, 'rentalProperties');
    const propertiesSnapshot = await getDocs(rentalPropertiesRef);
    
    const allBookingRequests = [];
    
    // For each property, get its booking requests
    for (const propertyDoc of propertiesSnapshot.docs) {
      const propertyData = { id: propertyDoc.id, ...propertyDoc.data() };
      
      const bookingRequestsRef = collection(db, 'rentalProperties', propertyDoc.id, 'bookingRequests');
      const bookingQuery = query(bookingRequestsRef, orderBy('createdAt', 'desc'));
      const bookingSnapshot = await getDocs(bookingQuery);
      
      bookingSnapshot.forEach((bookingDoc) => {
        allBookingRequests.push({
          id: bookingDoc.id,
          propertyId: propertyDoc.id,
          propertyName: propertyData.name || propertyData.propertyInfo?.name,
          propertySlug: propertyData.propertyInfo?.slug,
          agentName: propertyData.agentInfo?.name,
          agentEmail: propertyData.agentInfo?.email,
          ...bookingDoc.data()
        });
      });
    }
    
    // Sort all booking requests by creation date
    allBookingRequests.sort((a, b) => {
      const dateA = a.createdAt?.toDate?.() || new Date(a.createdAt) || new Date(0);
      const dateB = b.createdAt?.toDate?.() || new Date(b.createdAt) || new Date(0);
      return dateB - dateA;
    });
    
    return { success: true, data: allBookingRequests };
  } catch (error) {
    console.error('Error fetching all booking requests:', error);
    return { success: false, error: error.message };
  }
};

// ==========================================
// PORTFOLIO MANAGEMENT (CLEAN + FIXED)
// ==========================================

// Add portfolio item
export const addPortfolioItem = async (data, category) => {
  try {
    const cat = (category || "").toLowerCase();

    let collectionName;
    switch (cat) {
      case "residential":
        collectionName = RESIDENTIAL_PORTFOLIO;
        break;
      case "land":
        collectionName = LAND_PORTFOLIO;
        break;
      default:
        return { success: false, error: "Invalid portfolio category" };
    }

    const docRef = await addDoc(collection(db, collectionName), {
      ...data,
      category: cat,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    return { success: true, id: docRef.id };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Update portfolio item
export const updatePortfolioItem = async (item, updateData) => {
  try {
    const category = (item.category || "").toLowerCase();

    let collectionName;
    switch (category) {
      case "residential":
        collectionName = RESIDENTIAL_PORTFOLIO;
        break;
      case "land":
        collectionName = LAND_PORTFOLIO;
        break;
      default:
        return { success: false, error: "Invalid portfolio category" };
    }

    const docRef = doc(db, collectionName, item.id);

    await updateDoc(docRef, {
      ...updateData,
      updatedAt: new Date(),
    });

    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Delete portfolio item
export const deletePortfolioItem = async (item) => {
  try {
    const category = (item.category || "").toLowerCase();

    let collectionName;
    switch (category) {
      case "residential":
        collectionName = RESIDENTIAL_PORTFOLIO;
        break;
      case "land":
        collectionName = LAND_PORTFOLIO;
        break;
      default:
        return { success: false, error: "Invalid portfolio category" };
    }

    await deleteDoc(doc(db, collectionName, item.id));

    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

export const getPortfolioItemById = async (id) => {
  try {
    for (const col of COLLECTIONS) {
      const ref = doc(db, col.name, id);
      const snap = await getDoc(ref);

      if (snap.exists()) {
        return {
          success: true,
          data: {
            id: snap.id,
            category: col.key, // ⭐ CRITICAL
            ...snap.data(),
          },
        };
      }
    }

    return { success: false, error: "Portfolio item not found" };
  } catch (error) {
    return { success: false, error: error.message };
  }
};



// Get items from one portfolio category
export const getPortfolioItems = async (category, filters = {}) => {
  try {
    const cat = (category || "").toLowerCase();

    let collectionName;
    switch (cat) {
      case "residential":
        collectionName = RESIDENTIAL_PORTFOLIO;
        break;
      case "land":
        collectionName = LAND_PORTFOLIO;
        break;
      default:
        return { success: false, error: "Invalid portfolio category" };
    }

    let q = collection(db, collectionName);

    if (filters.status) {
      q = query(q, where("status", "==", filters.status));
    }
    if (filters.subcategory) {
      q = query(q, where("subcategory", "==", filters.subcategory));
    }

    const snap = await getDocs(q);

    const items = snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      category: cat,
    }));

    // Sort by newest first
    items.sort((a, b) => {
      const aDate = a.createdAt?.toDate?.() || new Date(a.createdAt);
      const bDate = b.createdAt?.toDate?.() || new Date(b.createdAt);
      return bDate - aDate;
    });

    return { success: true, data: items };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Get all portfolio items across all categories
export const getAllPortfolioItems = async () => {
  try {
    const categories = ["residential", "land"];
    const all = [];

    for (const cat of categories) {
      const result = await getPortfolioItems(cat);
      if (result.success) all.push(...result.data);
    }

    all.sort((a, b) => {
      const aDate = a.createdAt?.toDate?.() || new Date(a.createdAt);
      const bDate = b.createdAt?.toDate?.() || new Date(b.createdAt);
      return bDate - aDate;
    });

    return { success: true, data: all };
  } catch (error) {
    return { success: false, error: error.message };
  }
};


// ==========================================
// AGENTS MANAGEMENT FUNCTIONS
// ==========================================

// Add agent
export const addAgent = async (agentData) => {
  try {
    const docRef = await addDoc(collection(db, AGENTS_COLLECTION), {
      ...agentData,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    return { success: true, id: docRef.id };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Get all agents
export const getAgents = async (filters = {}) => {
  try {
    let q = collection(db, AGENTS_COLLECTION);
    
    // Apply filters if needed
    if (filters.status) {
      q = query(q, where('status', '==', filters.status));
    }
    
    const querySnapshot = await getDocs(q);
    const agents = [];
    
    querySnapshot.forEach((doc) => {
      agents.push({ id: doc.id, ...doc.data() });
    });

    // Sort by creation date or name
    agents.sort((a, b) => {
      if (filters.sortBy === 'name') {
        return a.name.localeCompare(b.name);
      }
      const dateA = a.createdAt?.toDate?.() || new Date(a.createdAt) || new Date(0);
      const dateB = b.createdAt?.toDate?.() || new Date(b.createdAt) || new Date(0);
      return dateB - dateA;
    });

    return { success: true, data: agents };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Get single agent
export const getAgent = async (agentId) => {
  try {
    const docRef = doc(db, AGENTS_COLLECTION, agentId);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      return { success: true, data: { id: docSnap.id, ...docSnap.data() } };
    } else {
      return { success: false, error: 'Agent not found' };
    }
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Update agent
export const updateAgent = async (agentId, updateData) => {
  try {
    const docRef = doc(db, AGENTS_COLLECTION, agentId);
    await updateDoc(docRef, {
      ...updateData,
      updatedAt: new Date()
    });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Delete agent
export const deleteAgent = async (agentId) => {
  try {
    await deleteDoc(doc(db, AGENTS_COLLECTION, agentId));
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Bulk add agents (for migration)
export const bulkAddAgents = async (agentsArray) => {
  try {
    const results = [];
    for (const agentData of agentsArray) {
      const result = await addAgent(agentData);
      results.push(result);
    }
    return { success: true, results };
  } catch (error) {
    return { success: false, error: error.message };
  }
};  

// ==========================================
// ⭐ Schedule Property Viewing Requests
// ==========================================
export const saveViewingRequest = async (viewingData) => {
  try {
    const docRef = await addDoc(collection(db, PROPERTY_VIEWINGS_COLLECTION), {
      ...viewingData,
      // status: 'pending',           // pending → approved → rejected
      createdAt: new Date(),
      updatedAt: new Date()
    });

    return { success: true, id: docRef.id };
  } catch (error) {
    console.error("Error saving viewing request:", error);
    return { success: false, error: error.message };
  }
};
