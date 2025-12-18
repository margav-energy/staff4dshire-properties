/**
 * Middleware to filter data by company_id based on the authenticated user
 * Superadmins can access all companies, regular admins can only access their own company
 */

const pool = require('../db');

/**
 * Get the company_id context from the request
 * This assumes user info is attached to req.user (you'll need to add auth middleware)
 */
const getCompanyFilter = (req) => {
  const user = req.user; // Assume auth middleware sets this
  
  if (!user) {
    return null; // No user, no access
  }
  
  // Superadmins can access all companies (return null means no filter)
  if (user.is_superadmin || user.role === 'superadmin') {
    return null;
  }
  
  // Regular users can only access their own company
  return user.company_id;
};

/**
 * Build WHERE clause for company filtering
 */
const buildCompanyWhereClause = (req, existingWhere = '') => {
  const companyId = getCompanyFilter(req);
  
  if (companyId === null && !(req.user?.is_superadmin || req.user?.role === 'superadmin')) {
    // User doesn't have a company and isn't a superadmin
    return existingWhere ? `${existingWhere} AND FALSE` : 'WHERE FALSE';
  }
  
  if (companyId === null) {
    // Superadmin - no filter
    return existingWhere || '';
  }
  
  // Regular user - filter by company
  const clause = `company_id = '${companyId}'`;
  if (existingWhere) {
    return `${existingWhere} AND ${clause}`;
  }
  return `WHERE ${clause}`;
};

/**
 * Verify user can access a specific company
 */
const canAccessCompany = (req, companyId) => {
  const user = req.user;
  
  if (!user) return false;
  
  // Superadmins can access all companies
  if (user.is_superadmin || user.role === 'superadmin') {
    return true;
  }
  
  // Regular users can only access their own company
  return user.company_id === companyId;
};

/**
 * Verify user can access a specific resource by company_id
 */
const canAccessResource = async (req, tableName, resourceId) => {
  const user = req.user;
  
  if (!user) return false;
  
  // Superadmins can access all resources
  if (user.is_superadmin || user.role === 'superadmin') {
    return true;
  }
  
  // Check if resource belongs to user's company
  try {
    const result = await pool.query(
      `SELECT company_id FROM ${tableName} WHERE id = $1`,
      [resourceId]
    );
    
    if (result.rows.length === 0) {
      return false; // Resource doesn't exist
    }
    
    return result.rows[0].company_id === user.company_id;
  } catch (error) {
    console.error(`Error checking resource access: ${error}`);
    return false;
  }
};

module.exports = {
  getCompanyFilter,
  buildCompanyWhereClause,
  canAccessCompany,
  canAccessResource,
};



