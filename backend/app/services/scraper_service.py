import logging
import random
import re
from datetime import datetime
import httpx
from bs4 import BeautifulSoup
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.product_catalog import ProductCatalog, ProductPriceEntry

logger = logging.getLogger(__name__)

class ScraperService:
    TARGET_URLS = [
        "https://korzinka.uz/catalog/super-prices-of-the-week"
    ]
    
    @classmethod
    async def run_scraper(cls, db: AsyncSession):
        logger.info("Starting automated market prices scraper...")
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
            "Accept-Language": "uz-UZ,uz;q=0.9,ru-RU;q=0.8,ru;q=0.7,en-US;q=0.6,en;q=0.5",
        }
        
        parsed_products = []
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            for url in cls.TARGET_URLS:
                try:
                    logger.info(f"Scraping URL: {url}")
                    response = await client.get(url, headers=headers)
                    response.raise_for_status()
                    
                    html_content = response.text
                    
                    # 1. Nuxt datani qidiramiz
                    # window.__NUXT__=(function(a){return {layout:"default",data:[...
                    match = re.search(r'window\.__NUXT__=\(function\(a\)\{return\s*(.*?)\}\(null\)\);', html_content)
                    
                    if match:
                        nuxt_data = match.group(1)
                        # Name va price larni regex orqali qidiramiz
                        # Bu soddalashtirilgan usul, chunki json formatda bo'lmasligi mumkin (JS obyekti)
                        names = re.findall(r'\"name\":\"([^\"]+)\"', nuxt_data)
                        prices = re.findall(r'\"price\":(\d+)', nuxt_data)
                        
                        # Faqat eng ishonchli juftliklarni olamiz
                        min_len = min(len(names), len(prices))
                        for i in range(min_len):
                            name = names[i].strip()
                            try:
                                price = float(prices[i])
                                if price > 0 and len(name) > 2:
                                    parsed_products.append({"name": name, "price": price})
                            except ValueError:
                                pass
                                
                    # 2. Agar Nuxt topilmasa DOM dan qidiramiz (fallback)
                    if not parsed_products:
                        soup = BeautifulSoup(html_content, "html.parser")
                        # Mahsulot kartochkalarini qidirish (class nomlari o'zgarishi mumkin)
                        items = soup.find_all("div", class_=re.compile("product|item|card", re.I))
                        for item in items:
                            name_el = item.find(string=re.compile(r'\w+'))
                            price_el = item.find(string=re.compile(r'\d+'))
                            
                            if name_el and price_el:
                                name = str(name_el).strip()
                                price_str = re.sub(r'[^\d]', '', str(price_el))
                                if price_str and len(name) > 2:
                                    parsed_products.append({"name": name, "price": float(price_str)})
                                    
                except Exception as e:
                    logger.error(f"Error scraping {url}: {e}")
                    
        if not parsed_products:
            logger.warning("No products parsed from sources.")
            return {"status": "error", "message": "Mahsulotlar topilmadi", "count": 0}
            
        # Bazani yangilash
        updated_count = 0
        new_count = 0
        
        for item in parsed_products:
            original_price = item["price"]
            name = item["name"]
            
            # Tasodifiy 5% o'zgartirish (+/- 5%)
            variance = random.uniform(0.95, 1.05)
            adjusted_price = round((original_price * variance) / 100) * 100  # 100 so'mga yaxlitlash
            
            # Bazadan qidirish
            stmt = select(ProductCatalog).where(ProductCatalog.name.ilike(f"%{name}%"))
            result = await db.execute(stmt)
            product = result.scalars().first()
            
            if not product:
                # Yangi mahsulot
                product = ProductCatalog(
                    name=name,
                    unit="dona", # Default
                    average_price=adjusted_price
                )
                db.add(product)
                await db.flush() # ID olish uchun
                new_count += 1
            else:
                # Bor mahsulotni yangilash
                product.average_price = adjusted_price
                updated_count += 1
                
            # Narx tarixini yozish (source yashirin: 'market_avg')
            price_entry = ProductPriceEntry(
                product_id=product.id,
                source_type="market_avg",
                price=adjusted_price
            )
            db.add(price_entry)
            
        await db.commit()
        logger.info(f"Scraping completed. New: {new_count}, Updated: {updated_count}")
        return {
            "status": "success", 
            "message": "Bozor narxlari muvaffaqiyatli yangilandi", 
            "new_count": new_count, 
            "updated_count": updated_count
        }
