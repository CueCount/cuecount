class FinancialDataPoint {
  final String key;         // Unique identifier
  final String label;       // Human-friendly name
  final String category;    // Statement type
  final String? subcategory; // Grouping inside the statement

  FinancialDataPoint({
    required this.key,
    required this.label,
    required this.category,
    this.subcategory,
  });
}

final List<FinancialDataPoint> financialDataPoints = [

  // ==============================
  // INCOME STATEMENT
  // ==============================

  FinancialDataPoint(key: "revenue", label: "Total Revenue", category: "Income Statement"),
  FinancialDataPoint(key: "cogs", label: "Cost of Goods Sold", category: "Income Statement"),
  FinancialDataPoint(key: "gross_profit", label: "Gross Profit", category: "Income Statement"),
  FinancialDataPoint(key: "operating_expenses", label: "Operating Expenses", category: "Income Statement"),
  FinancialDataPoint(key: "rd_expense", label: "R&D Expense", category: "Income Statement", subcategory: "Operating Expenses"),
  FinancialDataPoint(key: "sales_marketing_expense", label: "Sales & Marketing Expense", category: "Income Statement", subcategory: "Operating Expenses"),
  FinancialDataPoint(key: "general_admin_expense", label: "General & Admin Expense", category: "Income Statement", subcategory: "Operating Expenses"),
  FinancialDataPoint(key: "operating_income", label: "Operating Income", category: "Income Statement"),
  FinancialDataPoint(key: "interest_expense", label: "Interest Expense", category: "Income Statement"),
  FinancialDataPoint(key: "interest_income", label: "Interest Income", category: "Income Statement"),
  FinancialDataPoint(key: "pretax_income", label: "Pre-Tax Income", category: "Income Statement"),
  FinancialDataPoint(key: "income_tax", label: "Income Tax", category: "Income Statement"),
  FinancialDataPoint(key: "net_income", label: "Net Income", category: "Income Statement"),
  FinancialDataPoint(key: "diluted_eps", label: "Diluted Earnings Per Share", category: "Income Statement"),
  FinancialDataPoint(key: "shares_outstanding", label: "Shares Outstanding", category: "Income Statement"),


  // ==============================
  // BALANCE SHEET
  // ==============================

  FinancialDataPoint(key: "cash", label: "Cash & Cash Equivalents", category: "Balance Sheet"),
  FinancialDataPoint(key: "short_term_investments", label: "Short-Term Investments", category: "Balance Sheet"),
  FinancialDataPoint(key: "accounts_receivable", label: "Accounts Receivable", category: "Balance Sheet"),
  FinancialDataPoint(key: "inventory", label: "Inventory", category: "Balance Sheet"),
  FinancialDataPoint(key: "other_current_assets", label: "Other Current Assets", category: "Balance Sheet"),
  FinancialDataPoint(key: "total_current_assets", label: "Total Current Assets", category: "Balance Sheet"),
  
  FinancialDataPoint(key: "pp&e", label: "Property, Plant & Equipment", category: "Balance Sheet"),
  FinancialDataPoint(key: "goodwill", label: "Goodwill", category: "Balance Sheet"),
  FinancialDataPoint(key: "intangible_assets", label: "Intangible Assets", category: "Balance Sheet"),
  FinancialDataPoint(key: "total_assets", label: "Total Assets", category: "Balance Sheet"),

  FinancialDataPoint(key: "accounts_payable", label: "Accounts Payable", category: "Balance Sheet"),
  FinancialDataPoint(key: "short_term_debt", label: "Short-Term Debt", category: "Balance Sheet"),
  FinancialDataPoint(key: "accrued_liabilities", label: "Accrued Liabilities", category: "Balance Sheet"),
  FinancialDataPoint(key: "total_current_liabilities", label: "Total Current Liabilities", category: "Balance Sheet"),

  FinancialDataPoint(key: "long_term_debt", label: "Long-Term Debt", category: "Balance Sheet"),
  FinancialDataPoint(key: "other_liabilities", label: "Other Liabilities", category: "Balance Sheet"),
  FinancialDataPoint(key: "total_liabilities", label: "Total Liabilities", category: "Balance Sheet"),

  FinancialDataPoint(key: "common_stock", label: "Common Stock", category: "Balance Sheet", subcategory: "Equity"),
  FinancialDataPoint(key: "additional_paid_in_capital", label: "Additional Paid-In Capital", category: "Balance Sheet", subcategory: "Equity"),
  FinancialDataPoint(key: "treasury_stock", label: "Treasury Stock", category: "Balance Sheet", subcategory: "Equity"),
  FinancialDataPoint(key: "retained_earnings", label: "Retained Earnings", category: "Balance Sheet", subcategory: "Equity"),
  FinancialDataPoint(key: "accum_comp_income", label: "Accumulated Other Comprehensive Income", category: "Balance Sheet", subcategory: "Equity"),
  FinancialDataPoint(key: "total_equity", label: "Total Shareholder Equity", category: "Balance Sheet", subcategory: "Equity"),


  // ==============================
  // CASH FLOW STATEMENT
  // ==============================

  // Operating Cash Flow
  FinancialDataPoint(key: "net_income_cf", label: "Net Income (Cash Flow)", category: "Cash Flow", subcategory: "Operating"),
  FinancialDataPoint(key: "depreciation_amortization", label: "Depreciation & Amortization", category: "Cash Flow", subcategory: "Operating"),
  FinancialDataPoint(key: "stock_based_comp", label: "Stock Based Compensation", category: "Cash Flow", subcategory: "Operating"),
  FinancialDataPoint(key: "change_in_working_cap", label: "Change in Working Capital", category: "Cash Flow", subcategory: "Operating"),
  FinancialDataPoint(key: "cash_from_operations", label: "Cash From Operations", category: "Cash Flow", subcategory: "Operating"),

  // Investing Cash Flow
  FinancialDataPoint(key: "capex", label: "Capital Expenditures", category: "Cash Flow", subcategory: "Investing"),
  FinancialDataPoint(key: "acquisitions", label: "Acquisitions", category: "Cash Flow", subcategory: "Investing"),
  FinancialDataPoint(key: "investment_purchases", label: "Purchases of Investments", category: "Cash Flow", subcategory: "Investing"),
  FinancialDataPoint(key: "investment_sales", label: "Sales/Maturities of Investments", category: "Cash Flow", subcategory: "Investing"),
  FinancialDataPoint(key: "cash_from_investing", label: "Cash From Investing", category: "Cash Flow", subcategory: "Investing"),

  // Financing Cash Flow
  FinancialDataPoint(key: "debt_issued", label: "Debt Issued", category: "Cash Flow", subcategory: "Financing"),
  FinancialDataPoint(key: "debt_repaid", label: "Debt Repaid", category: "Cash Flow", subcategory: "Financing"),
  FinancialDataPoint(key: "stock_issued", label: "Stock Issued", category: "Cash Flow", subcategory: "Financing"),
  FinancialDataPoint(key: "stock_repurchase", label: "Stock Repurchase", category: "Cash Flow", subcategory: "Financing"),
  FinancialDataPoint(key: "dividends_paid", label: "Dividends Paid", category: "Cash Flow", subcategory: "Financing"),
  FinancialDataPoint(key: "cash_from_financing", label: "Cash From Financing", category: "Cash Flow", subcategory: "Financing"),

  FinancialDataPoint(key: "net_cash_change", label: "Net Change in Cash", category: "Cash Flow"),
  FinancialDataPoint(key: "end_cash_balance", label: "End Cash Balance", category: "Cash Flow"),


  // ==============================
  // SUPPLEMENTAL / NON-GAAP METRICS
  // ==============================

  FinancialDataPoint(key: "ebitda", label: "EBITDA", category: "Supplemental"),
  FinancialDataPoint(key: "adjusted_ebitda", label: "Adjusted EBITDA", category: "Supplemental"),
  FinancialDataPoint(key: "free_cash_flow", label: "Free Cash Flow", category: "Supplemental"),
  FinancialDataPoint(key: "gross_margin", label: "Gross Margin %", category: "Supplemental"),
  FinancialDataPoint(key: "operating_margin", label: "Operating Margin %", category: "Supplemental"),
  FinancialDataPoint(key: "net_margin", label: "Net Margin %", category: "Supplemental"),
  FinancialDataPoint(key: "total_debt", label: "Total Debt", category: "Supplemental"),
  FinancialDataPoint(key: "net_debt", label: "Net Debt", category: "Supplemental"),
  FinancialDataPoint(key: "current_ratio", label: "Current Ratio", category: "Supplemental"),
  FinancialDataPoint(key: "quick_ratio", label: "Quick Ratio", category: "Supplemental"),
];
